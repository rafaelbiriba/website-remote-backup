def get_backup_date
  @backup_date ||= Time.now.strftime(get_backup_date_format)
end

def get_backup_date_format
  "%d_%m_%Y-%H_%M"
end
