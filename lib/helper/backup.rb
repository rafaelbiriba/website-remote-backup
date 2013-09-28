def get_backup_date
  @backup_date ||= Time.now.strftime(get_backup_date_format)
end

def get_backup_date_format
  "%d_%m_%Y-%H_%M"
end

def local_git_cleaner path
  keep_commit = `cd #{path} && git rev-parse HEAD~20 2>&1`.strip!
  return unless $?.success?
  `cd #{path} && git filter-branch --parent-filter 'test $GIT_COMMIT == #{keep_commit} && echo "" || cat' HEAD 2>&1`
  `cd #{path} && git update-ref -d refs/original/refs/heads/master 2>&1`
  `cd #{path} && git reflog expire --expire=now --all 2>&1`
  `cd #{path} && git gc --prune=now 2>&1`
  `cd #{path} && git fsck --unreachable 2>&1`
end
