module TodoRunner
  module FileRenaming

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def rename_file path, task_name, status
        new_name = new_name path, task_name, status
        return path if path == new_name

        FileUtils.mv path, new_name
        new_name
      end

      def new_name path, task_name, status
        "#{path.sub(/[^.]+$/, '')}#{new_ext task_name, status}"
      end

      def new_ext task_name, status
        return task_name if DEFAULT_TASKS.include? task_name
        [task_name, status].join '-'
      end
    end
  end
end
