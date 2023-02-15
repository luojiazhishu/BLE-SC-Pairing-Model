SEPARATOR = ==============================================================================
File = BLE_SC_PAIRING.m4
# File = BLE_SC_PAIRING_PATCH.m4
# Set `File = BLE_SC_PAIRING_PATCH.m4` to verify our fixed BLE-SC pairing.
IOCapabilitys = DisplayOnly DisplayYesNo KeyboardOnly NoInputNoOutput KeyboardDisplay
Dir = BLEResults/Unfixed
# Dir should be renamed when using BLE_SC_PAIRING_PATCH.m4,
# Dir = BLEResults/Fixed
JWDir = $(Dir)/JW
NCDir = $(Dir)/NC
PEDir = $(Dir)/PE
OOBDir = $(Dir)/OOB
Threads = +RTS -N60 -RTS
Heuristic_S = --heuristic=S

# initialize device and user
# IO capabilities of the devices:
# 1.DisplayOnly
# 2.DisplayYesNo
# 3.KeyboardOnly
# 4.NoInputNoOutput
# 5.KeyboardDisplay

#				   			      1			      2				  3				   4				   5
#      	      Initiator      DisplayOnly     DisplayYesNo    KeyboardOnly    NoInputNoOutput     KeyboardDisplay
#  	   Responder                                                                                                      
# 1	DisplayOnly                  JW               JW             PE                JW                  PE        
# 2	DisplayYesNo                 JW        JW(Legacy)/NC(SC)     PE                JW            PE(Legacy)/NC(SC)
# 3	KeyboardOnly                 PE               PE             PE                JW                  PE       
# 4	NoInputNoOutput              JW               JW             JW                JW                  JW       
# 5	KeyboardDisplay              PE        PE(Legacy)/NC(SC)     PE                JW            PE(Legacy)/NC(SC)


Lemma = *

ifeq ($(Lemma),*)
    fnLemma=All
else 
	fnLemma=$(Lemma)
endif

dnl ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
divert(-1)
changequote(<!,!>)
define(CMDDefine,
<!-DIOCapabilityofInitiator=$1 -DOOBCapabilityofInitiatorOut=$2 -DOOBCapabilityofInitiatorIn=$3 -DMITMofInitiator=$4 -DIOCapabilityofResponder=$5 -DOOBCapabilityofResponderOut=$6 -DOOBCapabilityofResponderIn=$7 -DMITMofResponder=$8!>)
changequote
divert(0)dnl
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NCPE: NC PE

ALL: JW NC PE OOB
dnl ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
divert(-1)
changequote(<!,!>)
define(Generate_spthy,
<!m4 CMDDefine($(word $1, $(IOCapabilitys)),$2,$3,$4,$(word $5, $(IOCapabilitys)),$6,$7,$8) $(File) > ./$($9)/BLE_SC-ifelse($2$3$6$7,0000,$(word $1, $(IOCapabilitys))_$(word $5, $(IOCapabilitys)),$2$3$6$7).spthy!>)
define(TamarinProve,
<!tamarin-prover $(Heuristic_S) --prove=$(Lemma) ./$($9)/BLE_SC-ifelse($2$3$6$7,0000,$(word $1, $(IOCapabilitys))_$(word $5, $(IOCapabilitys)),$2$3$6$7).spthy --output=./$($9)/proofs/Out_$(fnLemma)_BLE_SC-ifelse($2$3$6$7,0000,$(word $1, $(IOCapabilitys))_$(word $5, $(IOCapabilitys)),$2$3$6$7).spthy > /tmp/.tmp
	echo >> ./$($9)/proofs/Out_$(fnLemma)_BLE_SC-ifelse($2$3$6$7,0000,$(word $1, $(IOCapabilitys))_$(word $5, $(IOCapabilitys)),$2$3$6$7).spthy
	cat /tmp/.tmp >> ./$($9)/proofs/Out_$(fnLemma)_BLE_SC-ifelse($2$3$6$7,0000,$(word $1, $(IOCapabilitys))_$(word $5, $(IOCapabilitys)),$2$3$6$7).spthy !>)
changequote
divert(0)dnl
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
JW:
	mkdir -p $(JWDir)
	mkdir -p $(JWDir)/proofs
dnl ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
divert(-1)
changequote(<!,!>)
define(JW_Generate_spthy,
<!Generate_spthy($1,0,0,1,$2,0,0,1,JWDir)!>)
define(JW_TamarinProve,
<!TamarinProve($1,0,0,1,$2,0,0,1,JWDir)!>)
define(JW_Generate_Prove,
<!JW_Generate_spthy($1,$2)
	JW_TamarinProve($1,$2)!>)
changequote
divert(0)dnl
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	m4 CMDDefine($(word 5, $(IOCapabilitys)),0,0,0,$(word 5, $(IOCapabilitys)),0,0,0) $(File) > ./$(JWDir)/BLE_SC-No_OOB-No_MITM.spthy
	tamarin-prover $(Heuristic_S) --prove=$(Lemma) ./$(JWDir)/BLE_SC-No_OOB-No_MITM.spthy --output=./$(JWDir)/proofs/Out_$(fnLemma)_BLE_SC-No_OOB-No_MITM.spthy > /tmp/.tmp
	echo >> ./$(JWDir)/proofs/Out_$(fnLemma)_BLE_SC-No_OOB-No_MITM.spthy
	cat /tmp/.tmp >> ./$(JWDir)/proofs/Out_$(fnLemma)_BLE_SC-No_OOB-No_MITM.spthy
	JW_Generate_Prove(1,1)
	JW_Generate_Prove(2,1)
	JW_Generate_Prove(4,1)
	JW_Generate_Prove(1,2)
	JW_Generate_Prove(4,2)
	JW_Generate_Prove(4,3)
	JW_Generate_Prove(1,4)
	JW_Generate_Prove(2,4)
	JW_Generate_Prove(3,4)
	JW_Generate_Prove(4,4)
	JW_Generate_Prove(5,4)
	JW_Generate_Prove(4,5)
	

NC:
	mkdir -p $(NCDir)
	mkdir -p $(NCDir)/proofs
dnl ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
divert(-1)
changequote(<!,!>)
define(NC_Generate_spthy,
<!Generate_spthy($1,0,0,1,$2,0,0,1,NCDir)!>)
define(NC_TamarinProve,
<!TamarinProve($1,0,0,1,$2,0,0,1,NCDir)!>)
define(NC_Generate_Prove,
<!NC_Generate_spthy($1,$2)
	NC_TamarinProve($1,$2)!>)
changequote
divert(0)dnl
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	NC_Generate_Prove(2,2)
	NC_Generate_Prove(5,2)
	NC_Generate_Prove(2,5)
	NC_Generate_Prove(5,5)

PE:
	mkdir -p $(PEDir)
	mkdir -p $(PEDir)/proofs
dnl ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
divert(-1)
changequote(<!,!>)
define(PE_Generate_spthy,
<!Generate_spthy($1,0,0,1,$2,0,0,1,PEDir)!>)
define(PE_TamarinProve,
<!TamarinProve($1,0,0,1,$2,0,0,1,PEDir)!>)
define(PE_Generate_Prove,
<!PE_Generate_spthy($1,$2)
	PE_TamarinProve($1,$2)!>)
changequote
divert(0)dnl
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	PE_Generate_Prove(3,1)
	PE_Generate_Prove(5,1)
	PE_Generate_Prove(3,2)
	PE_Generate_Prove(1,3)
	PE_Generate_Prove(2,3)
	PE_Generate_Prove(3,3)
	PE_Generate_Prove(5,3)
	PE_Generate_Prove(1,5)
	PE_Generate_Prove(3,5)

OOB:
	mkdir -p $(OOBDir)
	mkdir -p $(OOBDir)/proofs
	Generate_spthy(1,1,1,1,1,1,1,1,OOBDir) # bidirection OOB transmit
	TamarinProve(1,1,1,1,1,1,1,1,OOBDir)
	Generate_spthy(1,1,0,1,1,0,1,1,OOBDir) # OOB transmit from Initiator Device to Responder Device
	TamarinProve(1,1,0,1,1,0,1,1,OOBDir)
	Generate_spthy(1,0,1,1,1,1,0,1,OOBDir) # OOB transmit from Responder Device to Initiator Device
	TamarinProve(1,0,1,1,1,1,0,1,OOBDir)


dnl ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
divert(-1)
changequote(<!,!>)
define(cleanDef,
<!clean$1:
	@rm $($1Dir) -r!>)
changequote
divert(0)dnl
dnl ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
cleanDef()

cleanDef(JW)

cleanDef(NC)

cleanDef(PE)

cleanDef(OOB)