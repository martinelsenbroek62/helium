class Rule < ActiveRecord::Base
  belongs_to :survey
  belongs_to :organization
  belongs_to :question
  belongs_to :group
  belongs_to :answer_from, class_name: :Question

  validates :operator, presence: true
  validates :answer_from_id, presence: true

  def update_from_master!
    Rule.where(uuid: master_rule_uuid).first
  end

  def evaluate!
    puts ["Q:#{answer_from.text}: A:#{answer_from.answer}"]

    if answer_from_id.present?
      return false if answer_from.xshow? != true
      if resolves_to_true
        return true
      end
    end
  end

  def resolves_to_true
    case operator.to_s
    when /not equal/i
      answer_from.answer.to_s.downcase != value.to_s.downcase
    when /equals/i
      answer_from.answer.to_s.downcase == value.to_s.downcase
    when /not contain/i
      !value.to_s.downcase.in?(answer_from.answer.to_s.downcase.split('|').map(&:strip))
    when /contains/i
      value.to_s.downcase.in?(answer_from.answer.to_s.downcase.split('|').map(&:strip))
    when /(?=greater)(?=equal)/i
      answer_from.answer.to_s.to_i >= value.to_s.to_i
    when /greater/i
      answer_from.answer.to_s.to_i > value.to_s.to_i
    when /(?=less)(?=equal)/i
      answer_from.answer.to_s.to_i <= value.to_s.to_i
    when /less/i
      answer_from.answer.to_s.to_i < value.to_s.to_i
    when /like/i
      answer_from.answer.to_s.downcase =~ /#{value}/i
    when /present/i
      answer_from.answer.present?
    when /empty/i
      answer_from.answer.blank?
    end
  end
end
