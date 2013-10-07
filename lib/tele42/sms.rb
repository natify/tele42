module Tele42
  class SMS < ::Tele42::Base

    class InvalidFrom < StandardError; end
    class BadLoginDetails < StandardError; end
    class BadMessage < StandardError; end
    class BadNumber < StandardError; end
    class NotEnoughCredits < StandardError; end

    def check_route
      raise 'route should be set' if @route.empty? || @route.nil?
    end

    def default_params
      @default_params ||= super.merge('route' => @route)
    end

    def unicode!
      @unicode = true
    end

    def send_text(from, to, message)
      check_from(from)
      params = default_params.merge(
        'to' => to,
        'from' => from,
        'message' => generate_message_for(:text, message)
      )
      if @unicode
        params['coding'] = 'unicode'
      end
      res = connection.get('/api/current/send/message.php', params)
      parse_result(res)
    end

    def parse_result(res)
      data = res.body.split(',')
      if data[0].to_i == 1
        data[1]
      else
        parse_error(data)
      end
    end

    def parse_error
      case data[1].to_i
      when 1
        raise ::Tele42::SMS::BadLoginDetails
      when 2
        raise ::Tele42::SMS::BadMessage
      when 3
        raise ::Tele42::SMS::BadNumber, "Bad to number #{data[2]}"
      when 4
        raise ::Tele42::SMS::NotEnoughCredits
      end
    end

    def generate_message_for(type, message)
      case type
      when :text
        generate_text_message(message)
      end
    end

    def generate_text_message(message)
      if @unicode
        ::Kconv.kconv(message, ::NKF::UTF16, ::NKF::UTF8).unpack('H*').first
      else
        message.force_encoding('iso-8859-1')
      end
    end

    def check_from(from)
      unless from =~ /\A\d{1,15}\z/ || from =~ /\A[[:alnum:]]{1,11}\z/
        raise ::Tele42::SMS::InvalidFrom, 'invalid from format'
      end
    end

  end
end