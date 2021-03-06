class AuraStateMachine
  include Statesman::Machine

  state :unstarted, initial: true
  state :rejected
  state :accepted
  state :live
  state :archived

  # Happy flow - this is the normal path
  transition from: :unstarted, to: [:accepted, :rejected]
  transition from: :accepted,  to: :live
  transition from: :rejected,  to: :archived
  transition from: :live,      to: :archived

  # State disrupted - something's gone wrong, override requests, etc.
  transition from: :archived,  to: :live
  transition from: :rejected,  to: :accepted

  after_transition(to: :accepted) do |aura|
    AuraMailer.aura_approved(aura.user, aura).deliver_later
  end

  after_transition(to: :rejected) do |aura|
    AuraMailer.aura_rejected(aura.user, aura).deliver_later
  end

  after_transition(to: :live) do |aura|
    AuraMailer.aura_live(aura.user, aura).deliver_later
    AuraMailer.aura_ending_soon(aura.user, aura).deliver_later!(wait_until: aura.end_date - 1.day)
  end

  after_transition(to: :archived) do |aura|
    AuraMailer.aura_archived(aura.user, aura).deliver_later
  end

end
