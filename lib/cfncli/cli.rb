require 'thor'
require 'aws-sdk'
require 'cfncli/cloudformation'

module CfnCli
  class Cli < Thor
    method_option 'stack_name',
                  type: :string,
                  required: true,
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

    desc 'create', 'Creates a stack in Cloudformation'
    def create
      opts = process_params(options.dup)
      cfn.create_stack(opts) 
    end

    no_tasks do
      # Process the parameters to make them compliant with the Cloudformation API
      def process_params(opts)
        check_exclusivity(opts.keys, ['template_body', 'template_url'])
        check_exclusivity(opts.keys, ['disable_rollback', 'on_failure'])
        check_exclusivity(opts.keys, ['stack_policy_body', 'stack_policy_url'])

        opts['template_body'] = file_or_content(opts['template_body']) if opts['template_body']
        opts['stack_policy_body'] = file_or_content(opts['stack_policy_body']) if opts['stack_policy_body']

        opts['parameters'] = process_stack_parameters(opts['parameters']) if opts['parameters']

        opts
      end

      # Check if only one of the arguments is specified in the options
      # @param options [Arrray<String>] List of available options
      # @param exclusives [Array<String>] List of mutually exclusive options
      def check_exclusivity(options, exclusives)
        exclusive_options = options & exclusives
        if exclusive_options.size > 1
          fail Thor::Error, "Error: #{exclusive_options} are mutually exclusive."
        end
      end

      # Gets the content of a string that can either be the
      # content itself or a filename if beginning by @
      def file_or_content(str)
        return str if str.nil?
        return str unless str.start_with? '@'
        File.read(str[1..-1])
      end

      # Converts a parameters hash in the format expected by CloudFormation
      def process_stack_parameters(parameters)
        return {} unless parameters

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
