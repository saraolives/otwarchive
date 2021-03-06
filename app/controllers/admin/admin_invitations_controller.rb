class Admin::AdminInvitationsController < ApplicationController

  before_filter :admin_only

  def index
  end

  def create
    @invitation = current_admin.invitations.new(invitation_params)
    if @invitation.invitee_email.blank?
      flash[:error] = t('no_email', default: "Please enter an email address.")
      render action: 'index'
    elsif @invitation.save
      flash[:notice] = t('sent', default: "An invitation was sent to %{email_address}", email_address: @invitation.invitee_email)
      redirect_to admin_invitations_url
    else
      render action: 'index'
    end
  end

  def invite_from_queue
    InviteRequest.find(:all, order: :position, limit: invitation_params[:invite_from_queue].to_i).each do |request|
      request.invite_and_remove(current_admin)
    end
    InviteRequest.reset_order
    flash[:notice] = t('invited_from_queue', default: "%{count} people from the invite queue were invited.", count: invitation_params[:invite_from_queue].to_i)
    redirect_to admin_invitations_url
  end

  def grant_invites_to_users
    if invitation_params[:user_group] == "All"
      Invitation.grant_all(invitation_params[:number_of_invites].to_i)
    else
      Invitation.grant_empty(invitation_params[:number_of_invites].to_i)
    end
    flash[:notice] = t('invites_created', default: 'Invitations successfully created.')
    redirect_to admin_invitations_url
  end

  def find
    unless invitation_params[:user_name].blank?
      @user = User.find_by_login(invitation_params[:user_name])
      @hide_dashboard = true
      @invitations = @user.invitations if @user
    end
    if !invitation_params[:token].blank?
      @invitation = Invitation.find_by_token(invitation_params[:token])
    elsif !invitation_params[:invitee_email].blank?
      @invitations = Invitation.find(:all, conditions: ['invitee_email LIKE ?', '%' + invitation_params[:invitee_email] + '%'])
      @invitation = @invitations.first if @invitations.length == 1
    end
    unless @user || @invitation || @invitations
      flash.now[:error] = t('user_not_found', default: "No results were found. Try another search.")
    end
  end

  private

  def invitation_params
    params.require(:invitation).permit(:invitee_email, :invite_from_queue,
      :user_group, :number_of_invites, :user_name, :token)
  end
end
