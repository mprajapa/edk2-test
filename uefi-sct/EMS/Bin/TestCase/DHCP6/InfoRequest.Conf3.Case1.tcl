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
CaseLevel         CONFORMANCE
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        1F01566E-BD7D-440f-9D55-6CB766BD2EB8
CaseName        InfoRequest.Conf3.Case1
CaseCategory    DHCP6
CaseDescription {Test the InfoRequest Conformance of DHCP6 - Invoke InfoRequest() \
                 when OptionList contains client identity option. \
                 EFI_INVALID_PARAMETER should be returned.
                }
################################################################################

Include DHCP6/include/Dhcp6.inc.tcl

#
# Begin log ...
#
BeginLog
#
# BeginScope
#
BeginScope  _DHCP6_INFOREQUEST_CONF3_

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                                   R_Status
UINTN                                   R_Handle

#
# Create child.
#
Dhcp6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                       \
                "Dhcp6SB.CreateChild - Create Child 1"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle

BOOLEAN                                 R_SendClientId
SetVar R_SendClientId                   FALSE

#
# Build the Option Request Option
#
EFI_DHCP6_PACKET_OPTION                 R_OptionRequest
SetVar R_OptionRequest.OpCode           $Dhcp6OptRequestOption
SetVar R_OptionRequest.OpLen            4
UINT8                                   R_OptRequestData(4)
SetVar R_OptRequestData                 {0x00 0x17 0x00 0x18}
SetVar R_OptionRequest.Data             @R_OptRequestData

UINT32                                  R_OptionCount
SetVar R_OptionCount                    1

POINTER                                 R_OptionPtr
#
# Build an option of Client Id
#
EFI_DHCP6_PACKET_OPTION                 R_ClientId
SetVar R_ClientId.OpCode                $Dhcp6OptClientID
SetVar R_ClientId.OpLen                 14
UINT8                                   R_OptClientIdData(14)
SetVar R_OptClientIdData                {0x00 0x01 0x00 0x01 0x0f 0x7c 0x5b 0x70 \
                                         0x00 0x0e 0x0c 0xb7 0x88 0x8a  
                                        }
SetVar R_ClientId.Data                  @R_OptClientIdData

SetVar         R_OptionPtr              &@R_ClientId

POINTER                                 R_OptionList
SetVar R_OptionList                     &@R_OptionPtr

UINT32                                  R_Retransmission(4)
#
# Retransmission parameters
# Irt 1
# Mrc 2
# Mrt 3
# Mrd 2
#
SetVar R_Retransmission                 {1 2 3 2}

UINTN                                   R_ReplyCallback
UINTN                                   R_CallbackContext
#0: NULL 1: Abort 2: DoNothing
SetVar R_ReplyCallback                 2

#
# Check point: Call InfoRequest() when OptionList contains client identity option.
#              EFI_INVALID_PARAMETER should be returned.
#
Dhcp6->InfoRequest "@R_SendClientId, &@R_OptionRequest, @R_OptionCount, @R_OptionList, \
                                                     &@R_Retransmission, 0, @R_ReplyCallback, &@R_CallbackContext, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_INVALID_PARAMETER]
RecordAssertion $assert $Dhcp6InfoRequestConf3AssertionGuid001         \
                        "Dhcp6.InfoRequest - OptionList contains client identify option" \
                        "ReturnStatus - $R_Status, ExpectedStatus - $EFI_INVALID_PARAMETER"

#
# Destroy child.
#
Dhcp6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
GetAck

#
# EndScope
#
EndScope _DHCP6_INFOREQUEST_CONF3_
#
# End Log 
#
EndLog

