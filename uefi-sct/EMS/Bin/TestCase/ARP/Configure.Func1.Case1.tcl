# 
#  Copyright 2006 - 2010 Unified EFI, Inc.<BR> 
#  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
# 
#  This program and the accompanying materials
#  are licensed and made available under the terms and conditions of the BSD License
#  which accompanies this distribution.  The full text of the license may be found at 
#  http://opensource.org/licenses/bsd-license.php
# 
#  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
# 
################################################################################
CaseLevel         FUNCTION
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT

#
# test case Name, category, description, GUID...
#
CaseGuid        F7A212F8-2879-4416-9EA3-53FF23260F62
CaseName        Configure.Func1.Case1
CaseCategory    ARP
CaseDescription {This case is to test the function of ARP.Configure}
################################################################################

proc ArpDestroy {} {
  Arp->Delete {TRUE, NULL, &@R_Status}
  GetAck

  Arp->Delete {FALSE, NULL, &@R_Status}
  GetAck
 
  ArpServiceBinding->DestroyChild {@R_Handle, &@R_Status}
  GetAck
}

proc CleanUpEutEnvironment {} {
  EndCapture
  EndScope _ARP_FUNC_CONFORMANCE_
  VifDown 0
  EndLog
}

#
# Begin log ...
#
BeginLog

Include ARP/include/Arp.inc.tcl

set hostmac    [GetHostMac]
set targetmac  [GetTargetMac]

VifUp 0 172.16.210.162 255.255.255.0
BeginScope _ARP_FUNC_CONFORMANCE_

UINTN                            R_Status
UINTN                            R_Handle
EFI_IP_ADDRESS                   R_StationAddress
EFI_ARP_CONFIG_DATA              R_ArpConfigData
EFI_IP_ADDRESS                   R_TargetSwAddress
UINTN                            R_ResolvedEvent1
UINTN                            R_ResolvedEvent2
EFI_MAC_ADDRESS                  R_TargetHwAddress
UINTN                            R_EventContext

ArpServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "ArpSBP.CreateChild - Create Child 1"                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetIpv4Address R_StationAddress.v4     "172.16.210.102"
SetVar R_ArpConfigData.SwAddressType   0x800
SetVar R_ArpConfigData.SwAddressLength 4
SetVar R_ArpConfigData.StationAddress  &@R_StationAddress
SetVar R_ArpConfigData.EntryTimeOut    0
SetVar R_ArpConfigData.RetryCount      30
SetVar R_ArpConfigData.RetryTimeOut    5000000

#
# Check point
#
Arp->Configure {&@R_ArpConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Configure - Config Child 1"                               \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_EventContext 0
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_EventContext,   \
                 &@R_ResolvedEvent1, &@R_Status"
GetAck

set L_Filter "ether proto \\arp and src host 172.16.210.102"
StartCapture CCB $L_Filter

SetEthMacAddress R_TargetHwAddress 01:01:01:01:01:01
set R_TargetHwAddress [GetEthMacAddress R_TargetHwAddress]
puts $R_TargetHwAddress
SetIpv4Address R_TargetSwAddress.v4 "172.16.210.161"
Arp->Request {&@R_TargetSwAddress, @R_ResolvedEvent1, &@R_TargetHwAddress,      \
	            &@R_Status}

ReceiveCcbPacket CCB TmpPkt 10
if { ${CCB.received} == 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Arp.Request - Send Request"                                 \
                  "Packet not captured"

  ArpDestroy

  BS->CloseEvent "@R_ResolvedEvent1, &@R_Status"
  GetAck

  CleanUpEutEnvironment
  return
}

ParsePacket TmpPkt -t arp -arp_sha ARP_SHA

LocalEther  00:02:03:04:05:06
RemoteEther $ARP_SHA
LocalIp     172.16.210.161
RemoteIp    172.16.210.102

CreatePacket Pkt1 -t arp -arp_op 2 
SendPacket Pkt1

GetAck
set assert [VerifyReturnStatus R_Status $EFI_NOT_READY]

GetVar R_EventContext
if {$R_EventContext != 1} {
  set assert fail
}
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Request - Send request"                                   \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_READY,    \
                 Context - $R_EventContext, ExpectedContext - 1"

set R_TargetHwAddress [GetEthMacAddress R_TargetHwAddress]
if {[string compare -nocase $R_TargetHwAddress 00:02:03:04:05:06] == 0} {
  set assert pass
} else {
  set assert fail
}
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Request - R_TargetHwAddress is correct"                   \
                "Get - $R_TargetHwAddress, Expected - 00:02:03:04:05:06"

Arp->Delete {TRUE, NULL, &@R_Status}
GetAck

Arp->Delete {FALSE, NULL, &@R_Status}
GetAck

#
# Send ARP request
#
LocalEther  00:02:03:04:05:07
RemoteEther ff:ff:ff:ff:ff:ff
LocalIp     172.16.210.161
RemoteIp    172.16.210.102

CreatePayload ReqPktPayload const 18 0x0
CreatePacket ArpReqPkt -t arp -arp_op 1 -arp_tha 00:00:00:00:00:00 -arp_payload\
              ReqPktPayload
SendPacket ArpReqPkt

ReceiveCcbPacket CCB ReqReplyPkt 10
if { ${CCB.received} == 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Arp.Reply - Send Reply"                                     \
                  "Packet not captured"
} else {
  set assert pass
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Arp.Reply - Send Reply"                                     \
                  "Send Reply packet"
}

DumpPacket ReqReplyPkt

SetVar R_EventContext 0
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_EventContext,   \
                 &@R_ResolvedEvent2, &@R_Status"
GetAck

SetEthMacAddress R_TargetHwAddress 01:01:01:01:01:01
set R_TargetHwAddress [GetEthMacAddress R_TargetHwAddress]

SetIpv4Address R_TargetSwAddress.v4 "172.16.210.161"
Arp->Request {&@R_TargetSwAddress, @R_ResolvedEvent2, &@R_TargetHwAddress,      \
	            &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]

set R_TargetHwAddress [GetEthMacAddress R_TargetHwAddress]
if {[string compare -nocase $R_TargetHwAddress 00:02:03:04:05:07] == 0} {
  set assert pass
} else {
  set assert fail
}
RecordAssertion $assert $ArpConfigureFuncAssertionGuid001                      \
                "Arp.Request - R_TargetHwAddress is correct"                   \
                "Get - $R_TargetHwAddress, Expected - 00:02:03:04:05:07"

ArpDestroy

BS->CloseEvent "@R_ResolvedEvent1, &@R_Status"
GetAck
BS->CloseEvent "@R_ResolvedEvent2, &@R_Status"
GetAck

CleanUpEutEnvironment
