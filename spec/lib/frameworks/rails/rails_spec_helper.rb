def cookies
  @cookies ||= {}
  @cookies
end

def params
  @params ||= {}
  @params
end

class ActiveSupport
  class SecureRandom
    def self.base64(base)
      "mkkV9YNS70946Q=="
    end
  end
end
