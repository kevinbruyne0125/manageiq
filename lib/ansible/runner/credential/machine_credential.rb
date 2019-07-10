module Ansible
  class Runner
    class MachineCredential < Credential
      def self.auth_type
        "ManageIQ::Providers::EmbeddedAnsible::AutomationManager::MachineCredential"
      end

      def command_line
        {:user => auth.userid}.delete_blanks.merge(become_args)
      end

      def write_password_file
        password_hash = {
          "^SSH [pP]assword:$"    => auth.password,
          "^BECOME [pP]assword:$" => auth.become_password
        }.delete_blanks

        File.write(password_file, password_hash.to_yaml) if password_hash.present?

        write_ssh_key if auth.auth_key.present?
      end

      private

      def become_args
        return {} if auth.become_username.blank?

        {
          :become        => nil,
          :become_user   => auth.become_username,
          :become_method => auth.options.try(:[], :become_method) || "sudo"
        }
      end

      def write_ssh_key
        File.write(ssh_key_file, auth.auth_key)
      end
    end
  end
end
