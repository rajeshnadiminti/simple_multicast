

require "mfc"

#
# A OpenFlow controller class which handles IPv4 multicast.
#
class SimpleMulticast < Controller


  def start
    @mfc = MFC.new
  end


  def packet_in datapath_id, message
    if message.igmp?
      handle_igmp message
    else
      members = @mfc.members( message.ipv4_daddr )
      flow_mod datapath_id, members, message
      packet_out datapath_id, members, message
    end
  end


  ##############################################################################
  private
  ##############################################################################


  def handle_igmp message
    group = message.igmp_group
    port = message.in_port

    if message.igmp_v2_membership_report?
      @mfc.learn group, port
    elsif message.igmp_v2_leave_group?
      @mfc.remove group, port
    end
  end


  def flow_mod datapath_id, members, message
    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from( message ),
      :actions => output_actions( members ),
      :hard_timeout => 5
    )
  end


  def packet_out datapath_id, members, message
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => output_actions( members )
    )
  end


  def output_actions members
    members.collect do | each |
      ActionOutput.new( :port => each )
    end
  end
end

