def get_backup_date
  @backup_date ||= Time.now.strftime("%d_%m_%Y-%H_%M")
end