def cookies
  @cookies ||= {}
  @cookies
end

class ActiveSupport
  class SecureRandom
    def self.base64(base)
      "mkkV9YNS70946Q=="
    end
  end
end
