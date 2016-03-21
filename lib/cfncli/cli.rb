require 'thor'
require 'aws-sdk'

require 'cfncli/cloudformation'
require 'cfncli/config'
require 'cfncli/thor_yaml'

module CfnCli
  class Cli < Thor
    include ThorYamlLoader

    module ExitCode
      OK = 0
      STACK_ERROR = 1
      VALIDATION_ERROR = 2
    end

    # Global options
    class_option 'log_level',
                  type: :numeric,
                  default: 1,
                  desc: 'Log level to display (0=DEBUG, 1=INFO, 2=ERROR, 3=CRITICAL)'
  
    class_option 'config_file',
                  type: :string,
                  default: 'cfncli.yml',
                  desc: 'Configuration file'

    # Stack options
    method_option 'stack_name',
                  alias: '-n',
                  type: :string,
                  desc: 'Cloudformation stack name'

    method_option 'template_body',
                  type: :string,
                  desc: 'JSON string or file containing the template body.' \
                        ' This is exclusive with the template_url option. Use @filename to read' \
                        ' the template body from a file'

    method_option 'template_url',
                  type: :string,
                  desc: 'S3 URL to the Cloudformation template.' \
                        ' This is exclusive with the template_body option'

    method_option 'parameters',
                  type: :hash,
                  desc: 'Stack parameters. Pass each parameter in the form --parameters key1:value1 key2:value2 or use the @filename syntax to provide a JSON file'

    method_option 'parameters_file',
                  type: :string,
                  desc: 'Stack parameters file. It should be a JSON file using the same syntax as for the AWS CLI'

    method_option 'disable_rollback',
                  type: :boolean,
                  default: false,
                  desc: 'Disable rollbacks in case of a stack update failure'\
                        ' This is mutually exclusive with on_failure.'

    method_option 'timeout_in_minutes',
                  type: :boolean,
                  desc: 'Stack creation timeout (in minutes)'

    method_option 'notification_arns',
                  type: :array,
                  desc: 'List of SNS notification ARNs to publish stack related events'

    method_option 'capabilities',
                  type: :array,
                  enum: ['CAPABILITY_IAM'],
                  desc: 'A list of capabilities that you must specify before AWS CloudFormation can create or update certain stacks'

    method_option 'resource_types',
                  type: :array,
                  desc: 'The template resource types that you have permissions to work with for this create stack action, such as AWS::EC2::Instance, AWS::EC2::*, or Custom::MyCustomInstance'

    method_option 'on_failure',
                  type: :string,
                  enum: ['DO_NOTHING', 'ROLLBACK', 'DELETE'],
                  desc: 'Determines what action will be taken if the stack creation fails.' \
                        ' This is mutually exclusive with disable_rollback'

    method_option 'stack_policy_body',
                  type: :string,
                  desc: 'JSON String containing the stack policy body. The @filename syntax can be used.' 

    method_option 'stack_policy_url',
                  type: :string,
                  desc: 'S3 URL to a stack policy file.' \
                        ' This is mutually exclusive with stack_policy_body'

    method_option 'tags',
                  type: :hash,
                  desc: 'Key-value pairs to associate with this stack'

    # Application options
    method_option 'list_events',
                  alias: '-l',
                  type: :boolean,
                  default: true,
                  desc: 'List the stack events during the operation'

    method_option 'interval',
                  type: :numeric,
                  default: 10,
                  desc: 'Polling interval (in seconds) for the cloudformation events'

    method_option 'timeout',
                  type: :numeric,
                  default: 1800,
                  desc: 'Timeout (in seconds) for the stack creation'

    method_option 'fail_on_noop',
                  type: :boolean,
                  default: false,
                  desc: 'Fails if a stack has nothing to update'

    desc 'apply', 'Creates a stack in Cloudformation'
    def apply
      opts = process_params(options)

      stack_name = opts['stack_name']
      fail ArgumentError, 'stack_name is required' unless stack_name
     
      retries = timeout / interval 
      fail_on_noop = consume_option(opts, 'fail_on_noop')
      list_events = consume_option(opts, 'list_events')
      config_file = consume_option(opts, 'config_file')

      ENV['CFNCLI_LOG_LEVEL'] = consume_option(opts, 'log_level').to_s

      client_config = Config::CfnClient.new(interval, retries, fail_on_noop)

      res = ExitCode::OK 
      if list_events
        cfn.apply_and_list_events(opts, client_config) 
        res = ExitCode::STACK_ERROR unless cfn.stack_successful? stack_name
      else
        cfn.create_stack(opts, client_config)
      end

      puts "Stack creation #{res == 0 ? 'successful' : 'failed'}"
      exit res
    rescue Aws::CloudFormation::Errors::ValidationError => e
      puts e.message
      exit ExitCode::VALIDATION_ERROR
    end

    method_option 'stack_name',
                  alias: '-n',
                  type: :string,
                  desc: 'Name or ID of the Cloudformation stack'

    # Application options.
    method_option 'interval',
                  type: :numeric,
                  default: 10,
                  desc: 'Polling interval (in seconds) for the cloudformation events'

    method_option 'timeout',
                  type: :numeric,
                  default: 1800,
                  desc: 'Timeout (in seconds) for the stack event listing'

    desc 'events', 'Displays the events for a stack in realtime'
    def events
      stack_name = options['stack_name']
      
      fail ArgumentError, 'stack_name is required' unless stack_name
      
      config = Config::CfnClient.new(options['interval'], options['retries'])
      cfn.events(stack_name, config)
    end
    
    method_option 'stack_name',
                  alias: '-n',
                  type: :string,
                  desc: 'Name or ID of the Cloudformation stack'

    # Application options.
    method_option 'interval',
                  type: :numeric,
                  default: 10,
                  desc: 'Polling interval (in seconds) for the cloudformation events'

    method_option 'timeout',
                  type: :numeric,
                  default: 1800,
                  desc: 'Timeout (in seconds) for the stack event listing'

    desc 'delete', 'Deletes a stack'
    def delete
      opts = options.dup
      stack_name = opts['stack_name']
      
      fail ArgumentError, 'stack_name is required' unless stack_name
      
      interval = consume_option(opts, 'interval')
      timeout = consume_option(opts, 'timeout')
      consume_option(opts, 'log_level')
      consume_option(opts, 'config_file')
      retries = timeout / interval

      config = Config::CfnClient.new(interval, retries)
      cfn.delete_stack(opts, config)
    end

    no_tasks do
      # Reads an option from a hash and deletes it
      # @param opts [Hash] Hash containing the options
      # @param option Key to consume
      # @return value of Key option in opts
      def consume_option(opts, option)
        res = opts[option]
        opts.delete(option)
        res
      end

      # Process the parameters to make them compliant with the Cloudformation API
      # @param opts [Hash] Hash containing the options. The hash will not be modified
      # @return the processed options hash
      def process_params(opts)
        opts = opts.dup
        check_exclusivity(opts.keys, ['template_body', 'template_url'])
        check_exclusivity(opts.keys, ['disable_rollback', 'on_failure'])
        check_exclusivity(opts.keys, ['stack_policy_body', 'stack_policy_url'])
        check_exclusivity(opts.keys, ['parameters', 'parameters_file'])

        opts['template_body'] = file_or_content(opts['template_body']) if opts['template_body']
        opts['stack_policy_body'] = file_or_content(opts['stack_policy_body']) if opts['stack_policy_body']
        opts['parameters'] = process_stack_parameters(opts['parameters']) if opts['parameters']
        opts['parameters'] = process_stack_parameters_file(consume_option(opts, 'parameters_file')) if opts['parameters_file']

        opts
      end

      # Check if only one of the arguments is specified in the options
      # @param options [Arrray<String>] List of available options
      # @param exclusives [Array<String>] List of mutually exclusive options
      def check_exclusivity(opts, exclusives)
        exclusive_options = opts & exclusives
        if exclusive_options.size > 1
          fail Thor::Error, "Error: #{exclusive_options} are mutually exclusive."
        end
      end

      # Gets the content of a string that can either be the
      # content itself or a filename if beginning by @
      # @param str [String] String containing either the content or the filename to read
      def file_or_content(str)
        return str if str.nil?
        return str unless file_param? str

        content = File.read(str[1..-1])
        content
      end

      # Indicates if the parameter is a file (as opposed to a value)
      # This is indicated by a leading @
      def file_param?(param)
        return false unless param.is_a? String
        param.start_with? '@'
      end

      # Converts a parameter JSON file to the format expected by CloudFormation
      # @param filename Path to the JSON file containing the parameters description
      # @return 
      def process_stack_parameters_file(filename)
        content = File.read(filename)
        return CloudFormation.parse_json_params(JSON.parse(content))
      end

      # Converts a parameters hash in the format expected by CloudFormation
      # @param parameters [Hash] Hash containing the parameters to convert
      def process_stack_parameters(parameters)
        return {} unless parameters

        # Returns the content of the file if parameters is a file
        return file_or_content(parameters) if file_param? parameters

        # Otherwise convert each param to the cfn structure
        parameters.map do |key, value|
          {
            parameter_key: key,
            parameter_value: value
          }
        end
      end

      # Cloudformation utility object
      def cfn
        @cfn ||= CfnCli::CloudFormation.new
      end
    end
  end
end
