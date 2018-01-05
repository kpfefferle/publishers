require "test_helper"
require "shared/mailer_test_helper"
require "webmock/minitest"

class ChannelsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionMailer::TestHelper
  include MailerTestHelper
  include PublishersHelper

  test "update a channel belonging to logged in owner succeeds" do
    publisher = publishers(:verified)

    sign_in publishers(:verified)

    channel = channels(:verified)
    assert channel.show_verification_status

    update_params = {
        channel: {
          show_verification_status: false
        }
    }
    url = channel_url(channel.id)

    perform_enqueued_jobs do
      patch(url,
            params: update_params,
            headers: { 'HTTP_ACCEPT' => "application/json" })
      assert_response 204
    end

    channel.reload

    refute channel.show_verification_status
  end

  test "update a channel that doesn't belong to logged in owner fails" do
    publisher = publishers(:verified)

    sign_in publishers(:verified)

    channel = channels(:google_verified)
    refute channel.show_verification_status

    update_params = {
        channel: {
            show_verification_status: true
        }
    }
    url = channel_url(channel.id)

    perform_enqueued_jobs do
      patch(url,
            params: update_params,
            headers: { 'HTTP_ACCEPT' => "application/json" })
      assert_response 302
      assert_redirected_to home_publishers_path
    end

    channel.reload

    refute channel.show_verification_status
  end

  test "delete removes a channel and associated details" do
    publisher = publishers(:small_media_group)
    channel = channels(:small_media_group_to_delete)
    sign_in publisher
    assert_difference("publisher.channels.count", -1) do
      assert_difference("SiteChannelDetails.count", -1) do
        delete channel_path(channel)
        assert_response 302
      end
    end
    assert_redirected_to home_publishers_path
  end

  test "delete does not remove a channel and associated details if channel does not belong to publisher" do
    publisher = publishers(:small_media_group)
    channel = channels(:global_verified)
    sign_in publisher
    assert_difference("publisher.channels.count", 0) do
      assert_difference("SiteChannelDetails.count", 0) do
        delete channel_path(channel)
        assert_response 302
      end
    end
    assert_redirected_to home_publishers_path
  end

  # ToDo:
  # test "a channel's show_verification_status can be updated via an ajax patch" do
  #   perform_enqueued_jobs do
  #     post(publishers_path, params: SIGNUP_PARAMS)
  #   end
  #   publisher = Publisher.order(created_at: :asc).last
  #   url = publisher_url(publisher, token: publisher.authentication_token)
  #   get(url)
  #   follow_redirect!
  #   perform_enqueued_jobs do
  #     patch(update_unverified_publishers_path, params: PUBLISHER_PARAMS)
  #   end
  #
  #   publisher.show_verification_status = false
  #   publisher.verified = true
  #   publisher.save!
  #
  #   assert_equal false, publisher.show_verification_status
  #
  #   url = publishers_path
  #   patch(url,
  #         params: { publisher: { show_verification_status: 1, pending_email: 'joeblow@example.com', name: 'Joseph Blow' } },
  #         headers: { 'HTTP_ACCEPT' => "application/json" })
  #   assert_response 204
  #
  #   publisher.reload
  #   assert_equal true, publisher.show_verification_status
  #   assert_equal 'joeblow@example.com', publisher.pending_email
  #   assert_equal 'Joseph Blow', publisher.name
  # end
  #
  # test "a channel's domain status can be polled via ajax" do
  #   perform_enqueued_jobs do
  #     post(publishers_path, params: SIGNUP_PARAMS)
  #   end
  #   publisher = Publisher.order(created_at: :asc).last
  #   url = publisher_url(publisher, token: publisher.authentication_token)
  #   get(url)
  #   follow_redirect!
  #
  #   url = domain_status_publishers_path
  #
  #   # domain has not been set yet
  #   get(url, headers: { 'HTTP_ACCEPT' => "application/json" })
  #   assert_response 404
  #
  #   update_params = {
  #       publisher: {
  #           brave_publisher_id_unnormalized: "pyramid.net",
  #           name: "Alice the Pyramid",
  #           phone: "+14159001420"
  #       }
  #   }
  #
  #   perform_enqueued_jobs do
  #     patch(update_unverified_publishers_path, params: update_params )
  #   end
  #
  #   # domain has been set
  #   get(url, headers: { 'HTTP_ACCEPT' => "application/json" })
  #   assert_response 200
  #   assert_match(
  #       '{"brave_publisher_id":"pyramid.net",' +
  #           '"next_step":"/publishers/verification_choose_method"}',
  #       response.body)
  # end
  #
  # test "a channel's status can be polled via ajax" do
  #   perform_enqueued_jobs do
  #     post(publishers_path, params: SIGNUP_PARAMS)
  #   end
  #   publisher = Publisher.order(created_at: :asc).last
  #   url = publisher_url(publisher, token: publisher.authentication_token)
  #   get(url)
  #   follow_redirect!
  #   perform_enqueued_jobs do
  #     patch(update_unverified_publishers_path, params: PUBLISHER_PARAMS)
  #   end
  #
  #   publisher.show_verification_status = false
  #   publisher.verified = true
  #   publisher.save!
  #
  #   assert_equal false, publisher.show_verification_status
  #
  #   url = status_publishers_path
  #   get(url,
  #       headers: { 'HTTP_ACCEPT' => "application/json" })
  #
  #   assert_response 200
  #   assert_match(
  #       '{"status":"uphold_unconnected",' +
  #           '"status_description":"You need to create a wallet with Uphold to receive contributions from Brave Payments.",' +
  #           '"timeout_message":null,' +
  #           '"uphold_status":"unconnected",' +
  #           '"uphold_status_description":"Not connected to Uphold."}',
  #       response.body)
  # end
end
