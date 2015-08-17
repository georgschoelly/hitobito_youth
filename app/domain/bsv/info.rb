# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module Bsv
  class Info

    attr_reader :course

    class_attribute :leader_roles
    self.leader_roles = Event::Course.role_types.select { |role| role.kind == :leader }.flatten

    def initialize(course)
      @course = course
    end

    def vereinbarungs_id_fiver
      course.kind.vereinbarungs_id_fiver
    end

    def kurs_id_fiver
      course.kind.kurs_id_fiver
    end

    def location
      course.location
    end

    def first_event_date
      course.dates.order(:start_at).first.start_at.to_date
    end

    def training_days
      days = course.training_days
      (days * 2).round / 2.0 if days.present?
    end

    def participant_count
      participants_aged_17_to_30.
        select { |person| ch_resident?(person) }.count
    end

    def leader_count
      leaders.count
    end

    def canton_count
      cantons.count
    end

    def language_count
      1
    end

    def participants_aged_17_to_30
      participants.
        collect(&:person).
        select(&:birthday?).
        select { |person| aged_17_to_30?(person) }
    end

    private

    def participations
      @participations ||= course.
        participations.
        where(active: true).
        includes(:roles, person: :location)
    end

    def participations_for(role_types)
      participations.select { |p| contains_any?(role_types, p.roles.collect(&:class))  }
    end

    def cantons
      participants_aged_17_to_30.
        collect(&:canton).compact.uniq
    end

    def leaders
      participations_for(leader_roles)
    end

    def participants
      @participants ||= participations_for([Event::Course::Role::Participant])
    end

    def aged_17_to_30?(person)
      person.birthday.present? &&
        (17..30).cover?(first_event_date.year - person.birthday.year)
    end

    # how is this done in jubla
    def ch_resident?(person)
      Cantons.short_name_strings.include?(person.canton.to_s.downcase)
    end

    def contains_any?(required, existing)
      (required & existing).present?
    end
  end
end
