# == Schema Information
#
# Table name: candidate_educations
#
#  id           :integer          not null, primary key
#  candidate_id :integer
#  education    :string
#  start_date   :date
#  end_date     :date
#  institution  :string
#  specialty    :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  # factory :candidate_education do
  #   education "Средне-высшее"
  #   start_date  6.years.ago
  #   end_date 1.years.ago
  #   institution "НГУ"
  #   specialty "Специальность"
  #   candidate
  # end
end
