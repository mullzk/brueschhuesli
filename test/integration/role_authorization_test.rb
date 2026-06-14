# frozen_string_literal: true

require "test_helper"

class RoleAuthorizationTest < ActionDispatch::IntegrationTest
  # --- Reservations: viewing is open to all roles ----------------------------

  test "every role may view the reservation list" do
    %i[owner member external shared_account].each do |role|
      sign_in_as(role)
      get root_path

      assert_response :success
    end
  end

  test "external and shared_account may view a single reservation" do
    owner = create(:user, role: :owner)
    reservation = Reservation.create!(reservation_attrs(owner))
    %i[external shared_account].each do |role|
      sign_in_as(role)
      get reservation_path(reservation)

      assert_response :success
    end
  end

  # --- Reservations: creating/editing restricted to owner + member -----------

  test "external cannot reach the new-reservation form" do
    sign_in_as(:external)
    get new_reservation_path

    assert_forbidden
  end

  test "shared_account cannot create a reservation" do
    user = sign_in_as(:shared_account)

    assert_no_difference -> { Reservation.count } do
      post reservations_path, params: { reservation: reservation_attrs(user) }
    end
    assert_forbidden
  end

  test "external cannot edit or destroy a reservation" do
    owner = create(:user, role: :owner)
    reservation = Reservation.create!(reservation_attrs(owner))
    sign_in_as(:external)

    get edit_reservation_path(reservation)

    assert_forbidden

    delete reservation_path(reservation)

    assert_forbidden
    assert Reservation.exists?(reservation.id)
  end

  # --- Reservations: member is confined to their own ------------------------

  test "member creating a reservation is forced onto their own user_id" do
    member = sign_in_as(:member)
    other = create(:user, role: :owner)
    post reservations_path, params: { reservation: reservation_attrs(member, user_id: other.id) }

    assert_equal member, Reservation.last.user
  end

  test "member cannot edit a foreign reservation" do
    owner = create(:user, role: :owner)
    reservation = Reservation.create!(reservation_attrs(owner))
    sign_in_as(:member)
    patch reservation_path(reservation), params: { reservation: { comment: "hijack" } }

    assert_forbidden
    assert_not_equal "hijack", reservation.reload.comment
  end

  test "member cannot destroy a foreign reservation" do
    owner = create(:user, role: :owner)
    reservation = Reservation.create!(reservation_attrs(owner))
    sign_in_as(:member)
    delete reservation_path(reservation)

    assert_forbidden
    assert Reservation.exists?(reservation.id)
  end

  # --- Reservations: owner is admin-like ------------------------------------

  test "owner can create a reservation for another user" do
    sign_in_as(:owner)
    member = create(:user, role: :member)
    post reservations_path, params: { reservation: reservation_attrs(member) }

    assert_equal member, Reservation.last.user
  end

  test "owner can edit and destroy a foreign reservation" do
    member = create(:user, role: :member)
    reservation = Reservation.create!(reservation_attrs(member))
    sign_in_as(:owner)

    patch reservation_path(reservation), params: { reservation: { comment: "fixed" } }

    assert_equal "fixed", reservation.reload.comment

    delete reservation_path(reservation)

    assert_not Reservation.exists?(reservation.id)
  end

  # --- User management: reading the list vs. managing users ------------------

  test "member and shared_account may read the user list" do
    %i[member shared_account].each do |role|
      sign_in_as(role)
      get users_path

      assert_response :success
    end
  end

  test "external cannot read the user list" do
    sign_in_as(:external)
    get users_path

    assert_forbidden
  end

  test "non-owners cannot create users" do
    %i[member external shared_account].each do |role|
      sign_in_as(role)

      assert_no_difference -> { User.count } do
        post users_path, params: { user: { name: "X", email: "x@example.com", password: "password", role: "member" } }
      end
      assert_forbidden
    end
  end

  test "non-owners cannot destroy users" do
    %i[member external shared_account].each do |role|
      sign_in_as(role)
      other = create(:user, role: :member)
      delete user_path(other)

      assert_forbidden
      assert User.exists?(other.id)
    end
  end

  test "owner can manage users" do
    sign_in_as(:owner)
    get users_path

    assert_response :success

    assert_difference -> { User.count }, 1 do
      post users_path, params: { user: { name: "Neu", email: "neu@example.com", password: "password", role: "member" } }
    end
  end

  # --- User management: self-service for one's own account -------------------

  test "a member may edit and update their own account" do
    member = sign_in_as(:member)
    get edit_user_path(member)

    assert_response :success

    patch user_path(member), params: { user: { telefon: "079" } }

    assert_equal "079", member.reload.telefon
  end

  test "a member cannot edit another user's account" do
    other = create(:user, role: :member)
    sign_in_as(:member)
    get edit_user_path(other)

    assert_forbidden
  end

  test "a member cannot update another user's account" do
    other = create(:user, role: :member, telefon: "000")
    sign_in_as(:member)
    patch user_path(other), params: { user: { telefon: "999" } }

    assert_forbidden
    assert_equal "000", other.reload.telefon
  end

  test "a member cannot escalate their own role" do
    member = sign_in_as(:member)
    patch user_path(member), params: { user: { role: "owner" } }

    assert_not member.reload.owner?
  end

  # --- Password: every authenticated user manages their own ------------------

  test "an external user can change their own password" do
    sign_in_as(:external)
    patch password_path, params: { old_password: "password", user: { password: "newsecret", password_confirmation: "newsecret" } }

    assert_redirected_to users_path
  end

  # --- Abrechnung: owner + member + shared_account, not external -------------

  test "owner, member and shared_account may open the Abrechnung" do
    %i[owner member shared_account].each do |role|
      sign_in_as(role)
      get abrechnung_jahresstatistik_url

      assert_response :success
    end
  end

  test "external cannot open the Abrechnung" do
    sign_in_as(:external)
    get abrechnung_jahresstatistik_url

    assert_forbidden
  end

  private

  def sign_in_as(role)
    attrs = { role: role, password: "password" }
    attrs[:responsible_user] = create(:user, role: :owner) if role == :external
    user = create(:user, **attrs)
    post session_path, params: { name: user.name, password: "password" }
    user
  end

  def reservation_attrs(user, overrides = {})
    {
      user_id: user.id,
      start: at("2019-03-01 14:00"),
      finish: at("2019-03-01 18:00"),
      type_of_reservation: Reservation::KURZAUFENTHALT,
      is_exclusive: true,
      comment: ""
    }.merge(overrides)
  end

  def assert_forbidden
    assert_redirected_to root_path
    assert_equal "Dazu hast du keine Berechtigung.", flash[:notice]
  end
end
