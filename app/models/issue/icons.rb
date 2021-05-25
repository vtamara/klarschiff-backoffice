# frozen_string_literal: true

class Issue
  module Icons
    extend ActiveSupport::Concern

    def map_icon
      "icons/map/active/png/#{kind || 'blank'}-#{icon_color}.png"
    end

    def list_icon
      "icons/list/png/#{kind || 'blank'}-#{icon_color}-22px.png"
    end

    private

    def icon_color
      case status
      when 'received', 'reviewed' then 'red'
      when 'in_process' then 'yellow'
      when 'not_solvable', 'duplicate' then 'yellowgreen'
      when 'closed' then 'green'
      when 'deleted' then 'black'
      else
        'gray'
      end
    end
  end
end
