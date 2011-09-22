module ChallengeCore

  # Used to ensure allowed is no less than required
  def update_allowed_values
    PROMPT_TYPES.each do |prompt_type|
      required = required(prompt_type)
      eval("#{prompt_type}_num_allowed = required") if required > allowed(prompt_type)
    end
  end

  # HACK to avoid time zones being encoded
  def fix_time_zone
    return true if self.time_zone.nil?
    return true if ActiveSupport::TimeZone[self.time_zone]
    try = self.time_zone.gsub('&amp;', '&')
    self.time_zone = try if ActiveSupport::TimeZone[try]
  end
  
  
  # a couple of handy shorthand methods
  def required(type)
    self.send("#{type}_num_required")
  end
  
  def allowed(type)
    self.send("#{type}_num_allowed")
  end

  def allowed_range_string(type)
    "#{required(type)}" + (allowed(type) != required(type) ? " - #{allowed(type)}" : '')
  end

  #### Management 
  
  def user_allowed_to_see_signups?(user)
    self.collection.user_is_maintainer?(user)
  end
  
  def user_allowed_to_see_assignments?(user)
    self.collection.user_is_maintainer?(user)
  end

  def user_allowed_to_sign_up?(user)
    self.collection.user_is_maintainer?(user) || 
      (self.signup_open && (!self.collection.moderated? || self.collection.user_is_posting_participant?(user)))
  end

  module ClassMethods
    # override datetime setters so we can take strings
    def override_datetime_setters
      %w(signups_open_at signups_close_at assignments_due_at works_reveal_at authors_reveal_at).each do |datetime_attr|
        define_method("#{datetime_attr}_string") do
          self.send(datetime_attr).try(:strftime, ArchiveConfig.DEFAULT_DATETIME_FORMAT)
        end
        define_method("#{datetime_attr}_string=") do |datetimestring|
          self.send("#{datetime_attr}=", Timeliness.parse(datetimestring, :zone => (self.time_zone || Time.zone)))
        end
      end
    end
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
end