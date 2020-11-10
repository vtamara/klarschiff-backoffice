# frozen_string_literal: true

require 'mini_magick'

class Photo < ApplicationRecord
  include Logging

  enum status: { internal: 0, external: 1, deleted: 2 }, _prefix: true

  belongs_to :issue

  has_one_attached :file

  attr_reader :censor_rectangles
  attr_accessor :censor_width, :censor_height

  validates :confirmation_hash, presence: true, uniqueness: true
  validates :file, presence: true

  before_validation :set_confirmation_hash, on: :create

  def _modification
    nil
  end

  def _modification=(value)
    return if value.blank?
    case value
    when 'rotate'
      rotate_image
    when 'censor'
      censor_image
    end
  end

  def censor_rectangles=(string)
    @censor_rectangles = string.split(';').map { |str| CensorRectangle.new str }
  end

  private

  def current_image
    MiniMagick::Image.read(file.download).auto_orient
  end

  def save_modified_image(new_image)
    new_filename = file.filename
    new_content_type = file.content_type
    file.purge
    file.attach(io: File.open(new_image.path), filename: new_filename, content_type: new_content_type)
    reset_censor_settings
  end

  def censor_image
    new_image = current_image

    width, height = new_image.data['geometry'].fetch_values('width', 'height').map(&:to_f)
    censor_rectangles.each do |censor_rectangle|
      new_image.mogrify do |m|
        m << '-draw' << censor_rectangle.calculate(width, height, censor_width, censor_height)
      end
    end
    save_modified_image new_image
  end

  def reset_censor_settings
    @censor_rectangles = nil
    @censor_width = nil
    @censor_height = nil
  end

  def rotate_image
    new_image = current_image
    new_image = new_image.rotate 90
    save_modified_image(new_image)
  end

  def set_confirmation_hash
    self.confirmation_hash = SecureRandom.uuid
  end
end
