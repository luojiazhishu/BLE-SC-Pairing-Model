theory BLE_SC_JW_NC_PE_OOB
begin

builtins: diffie-hellman, symmetric-encryption
functions: f4/4, g2/4, f5/5, f6/7, resize/2

/*secure channel*/
rule send_authenticated [color=#9AFF9A]:
	[Out_A(<channelname,SendType,ReceiveType>,A,B,m)]
	-->
	[Auth(<channelname,SendType,ReceiveType>,A,B,m)]

rule receive_authenticated [color=#9AFF9A]:
	[Auth(<channelname,SendType,ReceiveType>,A,B,m)]
	-->
	[In_A(<channelname,SendType,ReceiveType>,A,B,m)]

/*An OOB channel*/
rule send_OOB [color=#9AFF9A]:
	[Out_OOB(<channelname,SendType,ReceiveType>,m)]
	--[]->
	[OOB(<channelname,SendType,ReceiveType>,m)]

rule receive_OOB [color=#9AFF9A]:
	[OOB(<channelname,SendType,ReceiveType>,m)]
	-->
	[In_OOB(<channelname,SendType,ReceiveType>,m)]

/*
initialize device and user
IO capabilities of the devices:
1.DisplayOnly
2.DisplayYesNo
3.KeyboardOnly
4.NoInputNoOutput
5.KeyboardDisplay

           Initiator      DisplayOnly     DisplayYesNo    KeyboardOnly    NoInputNoOutput     KeyboardDisplay
    Responder                                                                                                      
DisplayOnly                  JW               JW             PE                JW                  PE        
DisplayYesNo                 JW        JW(Legacy)/NC(SC)     PE                JW            PE(Legacy)/NC(SC)
KeyboardOnly                 PE               PE             PE                JW                  PE       
NoInputNoOutput              JW               JW             JW                JW                  JW       
KeyboardDisplay              PE        PE(Legacy)/NC(SC)     PE                JW            PE(Legacy)/NC(SC)
*/
divert(-1)
changequote(<!,!>)

define(Init_Initiator,
<!rule Init_InitDevice [color=#FFEFD5]:
    let
        IOCapability = $1
        OOBCapability = <'$2','$3'>
        MITM = $4
    in
    [
        Fr(~MacAdd),
        Fr(~skI)
    ]
    --[
        Unique($D),
        OnlyoneInit(),
        InitD_IOCapability($1),
        AFMITMI($4),
        InitDOOBOut('$2'),
        InitDOOBIn('$3')
    ]->
    [!Device($D,~MacAdd,IOCapability,OOBCapability,MITM,~skI,'Initiator')]

restriction OnlyoneInit:
    "All #i #j. OnlyoneInit()@#i & OnlyoneInit()@#j ==> #i = #j"!>)

define(Init_Responder,
<!rule Init_ResDevice [color=#FFEFD5]:
    let
        IOCapability = $1
        OOBCapability = <'$2','$3'>
        MITM = $4
    in
    [
        Fr(~MacAdd),
        Fr(~skR)
    ]
    --[
        Unique($D),
        OnlyoneRes(),
        ResD_IOCapability($1),
        AFMITMR($4),
        ResDOOBOut('$2'),
        ResDOOBIn('$3')
    ]->
    [
        !Device($D,~MacAdd,IOCapability,OOBCapability,MITM,~skR,'Responder')
    ]

restriction OnlyoneRes:
    "All #i #j. OnlyoneRes()@#i & OnlyoneRes()@#j ==> #i = #j"!>)

changequote

divert(0)dnl
dnl # IOCapabilityofInitiator defined by -DIOCapabilityofInitiator=** in command line
dnl # IOCapabilityofResponder defined by -DIOCapabilityofResponder=** in command line
Init_Initiator('IOCapabilityofInitiator',OOBCapabilityofInitiatorOut,OOBCapabilityofInitiatorIn,'MITMofInitiator')

Init_Responder('IOCapabilityofResponder',OOBCapabilityofResponderOut,OOBCapabilityofResponderIn,'MITMofResponder')

/*
** OOB transport start
*/
rule InitDOutOOBinfo [color=#BBFFFF]:
    let
        OOBCapabilityI = <'1',i>
        ra = ~ri
        rb = '0'
        DHpkI = 'g'^~skI
        Ca = f4(DHpkI,DHpkI,ra,'0')
    in
    [
        !Device(InitD,MacAddI,IOCapabilityI,OOBCapabilityI,MITMI,~skI,'Initiator'),
        Fr(~ri)
    ]
    --[]->
    [
        Out_OOB(<'OOB','InitD','ResD'>,<MacAddI,ra,Ca>),
        !State_InitD_SentOOBInfo(ra,Ca)
    ]


rule ResDOutOOBinfo [color=#FFF68F]:
    let
        OOBCapabilityR = <'1',i>
        ra = '0'
        rb = ~rr
        DHpkR = 'g'^~skR
        Cb = f4(DHpkR,DHpkR,rb,'0')
    in
    [
        !Device(ResD,MacAddR,IOCapabilityR,OOBCapabilityR,MITMR,~skR,'Responder'),
        Fr(~rr)
    ]
    --[]->
    [
        Out_OOB(<'OOB','ResD','InitD'>,<MacAddR,rb,Cb>),
        !State_ResD_SentOOBInfo(rb,Cb)
    ]

rule InitDInOOBinfo [color=#BBFFFF]:
    let
        OOBCapabilityI = <i,'1'>
    in
    [
        !Device(InitD,MacAddI,IOCapabilityI,OOBCapabilityI,MITMI,~skI,'Initiator'),
        In_OOB(<'OOB','ResD','InitD'>,<MacAddR,rb,Cb>)
    ]
    --[
        OnlyoneInitInOOB(InitD)
    ]->
    [
        !State_InitD_RevOOBInfo(MacAddR,rb,Cb)
    ]

restriction OnlyoneInitInOOB:
    "All x #i #j. OnlyoneInitInOOB(x)@#i & OnlyoneInitInOOB(x)@#j ==> #i = #j"
    
rule ResDInOOBinfo [color=#FFF68F]:
    let
        OOBCapabilityR = <i,'1'>
    in
    [
        !Device(ResD,MacAddR,IOCapabilityR,OOBCapabilityR,MITMR,~skR,'Responder'),
        In_OOB(<'OOB','InitD','ResD'>,<MacAddI,ra,Ca>)
    ]
    --[
        OnlyoneResInOOB(ResD)
    ]->
    [
        !State_ResD_RevOOBInfo(MacAddI,ra,Ca)
    ]

restriction OnlyoneResInOOB:
    "All x #i #j. OnlyoneResInOOB(x)@#i & OnlyoneResInOOB(x)@#j ==> #i = #j"

/*
*/

rule Init_User [color=#FFEFD5]:
    []
    --[OnlyoneUser()]->
    [!User($User)]

rule Advertising [color=#FFF68F]:
    [
        !Device(ResD,MacAddR,IOCapabilityR,OOBCapabilityR,MITMR,~skR,'Responder')
    ]
    --[]->
    [
        Out(<ResD,MacAddR>)
    ]

rule Scan [color=#BBFFFF]:
    [
        In(<ResD,MacAddR>),
        !Device(InitD,MacAddI,IOCapabilityI,OOBCapabilityI,MITMI,~skI,'Initiator')
    ]
    --[
        OneInitOneResD(InitD,ResD),
        Neq(InitD,ResD)
    ]->
    [
        State_Scaned(InitD,MacAddI,IOCapabilityI,MITMI,~skI,ResD,MacAddR)
    ]

// An initiator device only pairing one responder device at a time.
restriction OneInitOneResD:
    "All x y z #i #j. OneInitOneResD(x,y) @#i & OneInitOneResD(x,z) @#j ==> (#i = #j & y = z)"

/* Start Pairing
*/
rule InitDRequest [color=#BBFFFF]:
    let
        OOBflagI = '0'
        KeySizeInit = '16'
    in
    [
        State_Scaned(InitD,MacAddI,IOCapabilityI,MITMI,~skI,ResD,MacAddR)
    ]
    --[
        InitD_OOBFlag(OOBflagI)
    ]->
    [
        !Pairing(InitD,ResD),
        Out(<MacAddI,MacAddR,InitD,'Req',IOCapabilityI,OOBflagI,MITMI,KeySizeInit>),
        // SIZE: Initiator will OUT its key size.
        InitDReqPairing(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,ResD,MacAddR,~skI)
    ]

rule ResDSResponse [color=#FFF68F]:
    let
        OOBflagR = '0'
        KeySizeRes = '16'
    in
    [
        In(<MacAddI,MacAddR,InitD,'Req',IOCapabilityI,OOBflagI,MITMI,KeySizeInit>),
        // SIZE: Responder receive Initiator's key size.
        !Device(ResD,MacAddR,IOCapabilityR,OOBCapabilityR,MITMR,~skR,'Responder')
    ]
    --[
        AFResDOnlyOneThread(),
        ResD_OOBFlag(OOBflagR)
    ]->
    [
        !Pairing(InitD,ResD),
        ResDStartPairing(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR),
        Out(<MacAddR,MacAddI,'response',IOCapabilityR,OOBflagR,MITMR,KeySizeRes>),
        !InitDKeySize(KeySizeInit)
        // SIZE: A '!' fact for consuming.
    ]

restriction ResDOnlyOneThread:
    "All #i #j. AFResDOnlyOneThread() @i & AFResDOnlyOneThread() @j ==> #i = #j"

rule InitDRequestWithOOBflagI1 [color=#BBFFFF]:
    let
        OOBflagI = '1'
        KeySizeInit = '16'
    in
    [
        State_Scaned(InitD,MacAddI,IOCapabilityI,MITMI,~skI,ResD,MacAddR),
        !State_InitD_RevOOBInfo(MacAddR,rb,Cb)
    ]
    --[
        InitD_OOBFlag(OOBflagI),
        InitDOOB1()
    ]->
    [
        !Pairing(InitD,ResD),
        Out(<MacAddI,MacAddR,InitD,'Req',IOCapabilityI,OOBflagI,MITMI,KeySizeInit>),
        // SIZE:
        InitDReqPairing(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,ResD,MacAddR,~skI)
    ]

rule ResDSResponseWithOOBflagR1 [color=#FFF68F]:
    let
        OOBflagR = '1'
        KeySizeRes = '16'
    in
    [
        In(<MacAddI,MacAddR,InitD,'Req',IOCapabilityI,OOBflagI,MITMI,KeySizeInit>),
        // SIZE:
        !Device(ResD,MacAddR,IOCapabilityR,OOBCapabilityR,MITMR,~skR,'Responder'),
        !State_ResD_RevOOBInfo(MacAddI,ra,Ca)
    ]
    --[
        AFResDOnlyOneThread(),
        ResD_OOBFlag(OOBflagR),
        ResDOOB1()
    ]->
    [
        !Pairing(InitD,ResD),
        ResDStartPairing(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR),
        Out(<MacAddR,MacAddI,'response',IOCapabilityR,OOBflagR,MITMR,KeySizeRes>),
        !InitDKeySize(KeySizeInit)
    ]

restriction OOBCapToOOBFlagInitD:
    "All #i #j. ResDOOBOut('1')@i & InitDOOBIn('1') @j ==> (Ex #k. InitDOOB1() @k)"

restriction OOBCapToOOBFlagResD:
    "All #i #j. InitDOOBOut('1')@i & ResDOOBIn('1') @j ==> (Ex #k. ResDOOB1() @k)"



rule InitDStartPairing [color=#BBFFFF]:
    [
        In(<MacAddR,MacAddI,'response',IOCapabilityR,OOBflagR,MITMR,KeySizeRes>),
        InitDReqPairing(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,ResD,MacAddR,~skI)
    ]
    --[
    ]->
    [
        InitDStartPairing(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI),
        !ResDKeySize(KeySizeRes)
    ]


/*
model pairing
*/

/*
Public key exchange Start ------------------------------------------
Same for all protocols
*/
rule InitDSendDH [color=#BBFFFF]:
    let
        DHpkI = 'g'^~skI
    in
    [
        InitDStartPairing(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI)
    ]
    --[
    ]->
    [
        Out(<MacAddI,MacAddR,DHpkI>),
        InitDSentDH(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI)
    ]


rule ResDRecDHSendDH [color=#FFF68F]:
    let
        DHpkR = 'g'^~skR
        DHKeyR = DHpkI^~skR
    in
    [
        ResDStartPairing(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR),
        In(<MacAddI,MacAddR,DHpkI>)
    ]
    --[
        Running_Res(MacAddR,MacAddI,<'DHKey',DHKeyR>)
    ]->
    [
        Out(<MacAddR,MacAddI,DHpkR>),
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR)
    ]


rule InitDRevDH [color=#BBFFFF]:
    let
        DHKeyI = DHpkR^~skI
    in
    [
        InitDSentDH(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI),
        In(<MacAddR,MacAddI,DHpkR>)
    ]
    --[
        Running_Init(MacAddI,MacAddR,<'DHKey',DHKeyI>)
    ]->
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI)
    ]

/*
Public key exchange End ********************************************
*/

/*
Authentication stage 1 Start ------------------------------------------
Protocol dependent
*/
/*
Just Work
*/
divert(-1)
changequote(<!,!>)
define(Generate_JW_ResDCommitment,
<!rule JW_ResDCommitment_$1_$2 [color=#FFF68F]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        ra = '0'
        rb = '0'
        Cb = f4('g'^~skR,DHpkI,~Nb,'0')
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        Fr(~Nb)
    ]
    --[
        ResDJW()
    ]->
    [
        Out(<MacAddR,MacAddI,Cb>),
        JW_State_Res_Sent_Commitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb)
    ]!>)

define(Generate_JW_InitDSendNonce,
<!rule JW_InitDSendNonce_$1_$2 [color=#BBFFFF]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        ra = '0'
        rb = '0'
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        Fr(~Na),
        In(Cb)
    ]
    --[
        InitDJW()
    ]->
    [
        Out(<MacAddI,MacAddR,~Na>),
        JW_State_Init_Sent_Nonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb)
    ]!>)

define(Generate_JW_ResDCommitment_NoMITMSet,
<!rule JW_ResDCommitment_NoMITMSet [color=#FFF68F]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        MITMI = '0'
        MITMR = '0'
        ra = '0'
        rb = '0'
        Cb = f4('g'^~skR,DHpkI,~Nb,'0')
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        Fr(~Nb)
    ]
    --[
        ResDJW()
    ]->
    [
        Out(<MacAddR,MacAddI,Cb>),
        JW_State_Res_Sent_Commitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb)
    ]!>)

define(Generate_JW_InitDSendNonce_NoMITMSet,
<!rule JW_InitDSendNonce_NoMITMSet [color=#BBFFFF]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        MITMI = '0'
        MITMR = '0'
        ra = '0'
        rb = '0'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        Fr(~Na),
        In(Cb)
    ]
    --[
        InitDJW()
    ]->
    [
        Out(<MacAddI,MacAddR,~Na>),
        JW_State_Init_Sent_Nonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb)
    ]!>)

changequote
divert(0)dnl

Generate_JW_ResDCommitment_NoMITMSet()
Generate_JW_InitDSendNonce_NoMITMSet()
restriction NoMITMSetJW:
    "All #i #j. AFMITMI('0') @i & AFMITMR('0') @j==> (Ex #m #n. InitDJW() @m & ResDJW() @n)"

Generate_JW_ResDCommitment(DisplayOnly,DisplayOnly)
Generate_JW_ResDCommitment(DisplayYesNo,DisplayOnly)
Generate_JW_ResDCommitment(NoInputNoOutput,DisplayOnly)
Generate_JW_ResDCommitment(DisplayOnly,DisplayYesNo)
Generate_JW_ResDCommitment(NoInputNoOutput,DisplayYesNo)
Generate_JW_ResDCommitment(NoInputNoOutput,KeyboardOnly)
Generate_JW_ResDCommitment(DisplayOnly,NoInputNoOutput)
Generate_JW_ResDCommitment(DisplayYesNo,NoInputNoOutput)
Generate_JW_ResDCommitment(KeyboardOnly,NoInputNoOutput)
Generate_JW_ResDCommitment(NoInputNoOutput,NoInputNoOutput)
Generate_JW_ResDCommitment(KeyboardDisplay,NoInputNoOutput)
Generate_JW_ResDCommitment(NoInputNoOutput,KeyboardDisplay)

Generate_JW_InitDSendNonce(DisplayOnly,DisplayOnly)
Generate_JW_InitDSendNonce(DisplayYesNo,DisplayOnly)
Generate_JW_InitDSendNonce(NoInputNoOutput,DisplayOnly)
Generate_JW_InitDSendNonce(DisplayOnly,DisplayYesNo)
Generate_JW_InitDSendNonce(NoInputNoOutput,DisplayYesNo)
Generate_JW_InitDSendNonce(NoInputNoOutput,KeyboardOnly)
Generate_JW_InitDSendNonce(DisplayOnly,NoInputNoOutput)
Generate_JW_InitDSendNonce(DisplayYesNo,NoInputNoOutput)
Generate_JW_InitDSendNonce(KeyboardOnly,NoInputNoOutput)
Generate_JW_InitDSendNonce(NoInputNoOutput,NoInputNoOutput)
Generate_JW_InitDSendNonce(KeyboardDisplay,NoInputNoOutput)
Generate_JW_InitDSendNonce(NoInputNoOutput,KeyboardDisplay)


rule JW_ResDSendNonce [color=#FFF68F]:
    let
        Vb = g2(DHpkI,'g'^~skR,Na,~Nb)
    in
    [
        JW_State_Res_Sent_Commitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb),
        In(<MacAddI,MacAddR,Na>)
    ]
    --[]->
    [
        Out(<MacAddR,MacAddI,~Nb>),
        JW_State_Res_Checked(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]

rule JW_InitDCheck [color=#BBFFFF]:
    let
        Va = g2('g'^~skI,DHpkR,~Na,Nb)
    in
    [
        JW_State_Init_Sent_Nonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb),
        In(<MacAddR,MacAddI,Nb>)
    ]
    --[ 
        Eq(Cb,f4(DHpkR,'g'^~skI,Nb,'0')) 
    ]->
    [
        JW_State_Init_Checked(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]

rule JW_ResDOK [color=#FFF68F]:
    [
        JW_State_Res_Checked(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]
    --[]->
    [
        State_Res_OK(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]

rule JW_InitDOk [color=#BBFFFF]:
    [
        JW_State_Init_Checked(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]
    --[]->
    [
        State_Init_OK(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]

/*
Number Compare
*/
divert(-1)
changequote(<!,!>)
define(Generate_NC_ResDCommitment,
<!rule NC_ResDCommitment_$1_$2 [color=#FFF68F]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        ra = '0'
        rb = '0'
        Cb = f4('g'^~skR,DHpkI,~Nb,'0')
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        Fr(~Nb)
    ]
    --[]->
    [
        Out(<MacAddR,MacAddI,Cb>),
        NC_State_Res_Sent_Commitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb)
    ]!>)

define(Generate_NC_InitDSendNonce,
<!rule NC_InitDSendNonce_$1_$2 [color=#BBFFFF]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        ra = '0'
        rb = '0'
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        Fr(~Na),
        In(Cb)
    ]
    --[]->
    [
        Out(<MacAddI,MacAddR,~Na>),
        NC_State_Init_Sent_Nonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb)
    ]!>)

changequote
divert(0)dnl
Generate_NC_ResDCommitment(DisplayYesNo,DisplayYesNo)
Generate_NC_ResDCommitment(KeyboardDisplay,DisplayYesNo)
Generate_NC_ResDCommitment(DisplayYesNo,KeyboardDisplay)
Generate_NC_ResDCommitment(KeyboardDisplay,KeyboardDisplay)

Generate_NC_InitDSendNonce(DisplayYesNo,DisplayYesNo)
Generate_NC_InitDSendNonce(KeyboardDisplay,DisplayYesNo)
Generate_NC_InitDSendNonce(DisplayYesNo,KeyboardDisplay)
Generate_NC_InitDSendNonce(KeyboardDisplay,KeyboardDisplay)

rule NC_ResDSendNonceDisplay [color=#FFF68F]:
    let
        Vb = g2(DHpkI,'g'^~skR,Na,~Nb)
    in
    [
        NC_State_Res_Sent_Commitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb),
        In(<MacAddI,MacAddR,Na>)
    ]
    -->
    [
        Out(<MacAddR,MacAddI,~Nb>),
        Out_A(<'DisplayConfirm','Device','User'>,ResD,$User,Vb),
        NC_State_Res_Displayed(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]

rule NC_InitCheckDisplay [color=#BBFFFF]:
    let
        Va = g2('g'^~skI,DHpkR,~Na,Nb)
    in
    [
        NC_State_Init_Sent_Nonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb),
        In(<MacAddR,MacAddI,Nb>)
    ]
    --[ 
        Eq(Cb,f4(DHpkR,'g'^~skI,Nb,'0'))
    ]->
    [
        Out_A(<'DisplayConfirm','Device','User'>,InitD,$User,Va),
        NC_State_Init_Displayed(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]

rule NC_ResDOK [color=#FFF68F]:
    [
        NC_State_Res_Displayed(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb),
        In_A(<'Confirm','User','Device'>,$User,ResD,'T')
    ]
    --[
        ResDNC()
    ]->
    [
        State_Res_OK(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]

rule NC_InitDOk [color=#BBFFFF]:
    [
        NC_State_Init_Displayed(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb),
        In_A(<'Confirm','User','Device'>,$User,InitD,'T')
    ]
    --[
        InitDNC()
    ]->
    [
        State_Init_OK(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]
/*
Passkey Entry
*/
divert(-1)
changequote(<!,!>)

define(Generate_PE_InitDDisplay,
<!rule PE_InitDDisplay_$1_$2 [color=#BBFFFF]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        Fr(~r)
    ]
    -->
    [
        Out_A(<'Display','Device','User'>,InitD,$User,~r),
        PE_InitDDisplayed(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,~r)
    ]!>)

define(Generate_PE_InitDAskforInput,
<!rule PE_InitDAskforInput_$1_$2 [color=#BBFFFF]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI)
    ]
    -->
    [
        Out_A(<'AskforInput','Device','User'>,InitD,$User,'Input'),
        PE_InitDWaitInput(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI)
    ]!>)

define(Generate_PE_ResDDisplay,
<!rule PE_ResDDisplay_$1_$2 [color=#FFF68F]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        Fr(~r)
    ]
    -->
    [
        Out_A(<'Display','Device','User'>,ResD,$User,~r),
        PE_ResDDisplayed(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,~r)
    ]!>)

define(Generate_PE_ResDAskforInput,
<!rule PE_ResDAskforInput_$1_$2 [color=#FFF68F]:
    let
        OOBflagI = '0'
        OOBflagR = '0'
        IOCapabilityI = '$1'
        IOCapabilityR = '$2'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR)
    ]
    -->
    [
        Out_A(<'AskforInput','Device','User'>,ResD,$User,'Input'),
        PE_ResDWaitInput(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR)
    ]!>)

changequote
divert(0)dnl
//Initiator Device Display
Generate_PE_InitDDisplay(DisplayOnly,KeyboardOnly)
Generate_PE_InitDDisplay(DisplayYesNo,KeyboardOnly)
Generate_PE_InitDDisplay(KeyboardDisplay,KeyboardOnly)
Generate_PE_InitDDisplay(DisplayOnly,KeyboardDisplay)

//Initiator Device Ask for Input
Generate_PE_InitDAskforInput(KeyboardOnly,DisplayOnly)
Generate_PE_InitDAskforInput(KeyboardDisplay,DisplayOnly)
Generate_PE_InitDAskforInput(KeyboardOnly,DisplayYesNo)
Generate_PE_InitDAskforInput(KeyboardOnly,KeyboardOnly)
Generate_PE_InitDAskforInput(KeyboardOnly,KeyboardDisplay)

//Responder Device Display
Generate_PE_ResDDisplay(KeyboardOnly,DisplayOnly)
Generate_PE_ResDDisplay(KeyboardDisplay,DisplayOnly)
Generate_PE_ResDDisplay(KeyboardOnly,DisplayYesNo)
Generate_PE_ResDDisplay(KeyboardOnly,KeyboardDisplay)

//Responder Device Ask for Input
Generate_PE_ResDAskforInput(DisplayOnly,KeyboardOnly)
Generate_PE_ResDAskforInput(DisplayYesNo,KeyboardOnly)
Generate_PE_ResDAskforInput(KeyboardOnly,KeyboardOnly)
Generate_PE_ResDAskforInput(KeyboardDisplay,KeyboardOnly)
Generate_PE_ResDAskforInput(DisplayOnly,KeyboardDisplay)

rule PE_ResDUserInputInjectSecret [color=#FFF68F]:
    let
        ra = r
        rb = r
    in
    [
        PE_ResDWaitInput(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        In_A(<'Input','User','Device'>,$User,ResD,r)
    ]
    --[]->
    [
        PE_ResDInjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb),
        Out(<MacAddR,MacAddI,'KeypressNotification'>)
    ]

rule PE_InitDUserInputInjectSecret [color=#BBFFFF]:
    let
        ra = r
        rb = r
    in
    [
        PE_InitDWaitInput(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        In_A(<'Input','User','Device'>,$User,InitD,r)
    ]
    --[]->
    [
        PE_InitDInjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb),
        Out(<MacAddI,MacAddR,'KeypressNotification'>)
    ]

rule PE_InitDUserOKInjectSecret [color=#BBFFFF]:
    let
        ra = ~r
        rb = ~r
    in
    [
        PE_InitDDisplayed(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,~r),
        // In_A(<'Confirm','User','Device'>,$User,InitD,'T')
        In(<MacAddR,MacAddI,'KeypressNotification'>)
    ]
    --[]->
    [
        PE_InitDInjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb)
    ]

rule PE_ResDUserOKInjectSecret [color=#FFF68F]:
    let
        ra = ~r
        rb = ~r
    in
    [
        PE_ResDDisplayed(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,~r),
        // In_A(<'Confirm','User','Device'>,$User,ResD,'T')
        In(<MacAddI,MacAddR,'KeypressNotification'>)
    ]
    --[]->
    [
        PE_ResDInjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb)
    ]

rule PE_InitDCommitment [color=#BBFFFF]:
    let
        Ca = f4('g'^~skI,DHpkR,~Na,ra)
    in
    [
        PE_InitDInjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb),
        Fr(~Na)
    ]
    --[]->
    [
        Out(<MacAddI,MacAddR,Ca>),
        PE_InitDSentCommitment(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na)
    ]

rule PE_ResDCommitment [color=#FFF68F]:
    let
        Cb = f4('g'^~skR,DHpkI,~Nb,rb)
    in
    [
        PE_ResDInjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb),
        In(<MacAddI,MacAddR,Ca>),
        Fr(~Nb)
    ]
    --[]->
    [
        Out(<MacAddR,MacAddI,Cb>),
        PE_ResDSentCommitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb,Ca)
    ]

rule PE_InitDSendNonce [color=#BBFFFF]:
    [
        PE_InitDSentCommitment(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na),
        In(<MacAddR,MacAddI,Cb>)
    ]
    --[]->
    [
        Out(<MacAddI,MacAddR,~Na>),
        PE_InitDSentNonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb)
    ]

rule PE_ResDCheckSendNonceOK [color=#FFF68F]:
    [
        PE_ResDSentCommitment(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,~Nb,Ca),
        In(<MacAddI,MacAddR,Na>)
    ]
    --[
        Eq(Ca,f4(DHpkI,'g'^~skR,Na,rb)),
        ResDPE()
    ]->
    [
        Out(<MacAddR,MacAddI,~Nb>),
        State_Res_OK(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]

rule PE_InitDCheckOK [color=#BBFFFF]:
    [
        PE_InitDSentNonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Cb),
        In(<MacAddR,MacAddI,Nb>)
    ]
    --[
        Eq(Cb,f4(DHpkR,'g'^~skI,Nb,ra)),
        InitDPE()
    ]->
    [
        State_Init_OK(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]


/*
model user
*/
rule User_NC [color=#6495ED]:
    [
        !User(User),
        !Pairing(D1,D2),
        In_A(<'DisplayConfirm','Device','User'>,D1,User,m),
        In_A(<'DisplayConfirm','Device','User'>,D2,User,m)
    ]
    --[
        AFOneInteraction()
    ]->
    [
        Out_A(<'Confirm','User','Device'>,User,D1,'T'),
        Out_A(<'Confirm','User','Device'>,User,D2,'T')
    ]

rule User_PE_0 [color=#6495ED]:
    [
        !User(User),
        !Pairing(D1,D2),
        In_A(<'AskforInput','Device','User'>,D1,User,'Input'),
        In_A(<'AskforInput','Device','User'>,D2,User,'Input'),
        Fr(~passkey)
    ]
    --[
        AFOneInteraction()
    ]->
    [
        Out_A(<'Input','User','Device'>,User,D1,~passkey),
        Out_A(<'Input','User','Device'>,User,D2,~passkey)
    ]

rule User_PE_1 [color=#6495ED]:
    [
        !User(User),
        !Pairing(D1,D2),
        In_A(<'Display','Device','User'>,D1,User,m),
        In_A(<'AskforInput','Device','User'>,D2,User,'Input')
    ]
    --[
        AFOneInteraction()
    ]->
    [
        // Out_A(<'Confirm','User','Device'>,User,D1,'T'),
        Out_A(<'Input','User','Device'>,User,D2,m)
    ]

rule User_PE_2 [color=#6495ED]:
    [
        !User(User),
        !Pairing(D1,D2),
        In_A(<'AskforInput','Device','User'>,D1,User,'Input'),
        In_A(<'Display','Device','User'>,D2,User,m)
    ]
    --[
        AFOneInteraction()
    ]->
    [
        Out_A(<'Input','User','Device'>,User,D1,m)
        // Out_A(<'Confirm','User','Device'>,User,D2,'T')
    ]

rule User_UnderAttack_1 [color=#6495ED]:
    [
        !User(User),
        !Pairing(D1,D2),
        In_A(<'AskforInput','Device','User'>,D1,User,'Input'),
        In_A(<'DisplayConfirm','Device','User'>,D2,User,m)
    ]
    --[
        AFOneInteraction()
    ]->
    [
        Out_A(<'Input','User','Device'>,User,D1,m),
        Out_A(<'Confirm','User','Device'>,User,D2,'T')
    ]

rule User_UnderAttack_2 [color=#6495ED]:
    [
        !User(User),
        !Pairing(D1,D2),
        In_A(<'DisplayConfirm','Device','User'>,D1,User,m),
        In_A(<'AskforInput','Device','User'>,D2,User,'Input')
    ]
    --[
        AFOneInteraction()
    ]->
    [
        Out_A(<'Confirm','User','Device'>,User,D1,'T'),
        Out_A(<'Input','User','Device'>,User,D2,m)
    ]

// User Only perform one interaction
restriction OneInteraction:
    "All #i #j. AFOneInteraction()@#i & AFOneInteraction()@#j ==> #i = #j"

/*
Out of Band
*/
rule OOB_InitDInjectSecretsWithOOBflagR0I1 [color=#BBFFFF]:
    let
        OOBflagR = '0'
        ra = '0'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        !State_InitD_RevOOBInfo(MacAddR,rb,Cb)
    ]
    --[
        Eq(Cb,f4(DHpkR,DHpkR,rb,'0'))
    ]->
    [
        State_InitD_InjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb)
    ]
rule OOB_InitDInjectSecretsWithOOBflagR1I0 [color=#BBFFFF]:
    let
        OOBflagR = '1'
        rb = '0'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        !State_InitD_SentOOBInfo(ra,Ca)
    ]
    --[
    ]->
    [
        State_InitD_InjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb)
    ]
rule OOB_InitDInjectSecretsWithOOBflagR1I1 [color=#BBFFFF]:
    let
        OOBflagR = '1'
    in
    [
        InitDDHKey(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI),
        !State_InitD_RevOOBInfo(MacAddR,rb,Cb),
        !State_InitD_SentOOBInfo(ra,Ca)
    ]
    --[
        Eq(Cb,f4(DHpkR,DHpkR,rb,'0'))
    ]->
    [
        State_InitD_InjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb)
    ]


rule OOB_ResDInjectSecretsWithOOBflagI0R1 [color=#FFF68F]:
    let
        OOBflagI = '0'
        rb = '0'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        !State_ResD_RevOOBInfo(MacAddI,ra,Ca)
    ]
    --[
        Eq(Ca,f4(DHpkI,DHpkI,ra,'0'))
    ]->
    [
        State_ResD_InjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb)
    ]
rule OOB_ResDInjectSecretsWithOOBflagI1R0 [color=#FFF68F]:
    let
        OOBflagI = '1'
        ra = '0'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        !State_ResD_SentOOBInfo(rb,Cb)
    ]
    --[
    ]->
    [
        State_ResD_InjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb)
    ]
rule OOB_ResDInjectSecretsWithOOBflagI1R1 [color=#FFF68F]:
    let
        OOBflagI = '1'
    in
    [
        ResDDHKey(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR),
        !State_ResD_RevOOBInfo(MacAddI,ra,Ca),
        !State_ResD_SentOOBInfo(rb,Cb)
    ]
    --[
        Eq(Ca,f4(DHpkI,DHpkI,ra,'0'))
    ]->
    [
        State_ResD_InjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb)
    ]


rule OOB_InitDSendNonce [color=#BBFFFF]:
    [
        State_InitD_InjectSecret(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb),
        Fr(~Na)
    ]
    --[]->
    [
        Out(<MacAddI,MacAddR,~Na>),
        OOB_InitDSentNonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na)
    ]

rule OOB_ResDOK [color=#FFF68F]:
    [
        In(<MacAddI,MacAddR,Na>),
        State_ResD_InjectSecret(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb),
        Fr(~Nb)
    ]
    --[
        ResDOOB() 
    ]->
    [
        Out(<MacAddR,MacAddI,~Nb>),
        State_Res_OK(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb)
    ]

rule OOB_InitDOK [color=#BBFFFF]:
    [
        In(<MacAddR,MacAddI,Nb>),
        OOB_InitDSentNonce(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na)
    ]
    --[
        InitDOOB()
    ]->
    [
        State_Init_OK(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]

/*
Authentication stage 1 End ********************************************
*/


/*
Authentication stage 2 Start ------------------------------------------
Same for all protocols
*/
rule InitDSendEa [color=#BBFFFF]:
    let
        MacKeyI = fst(f5(DHKeyI,~Na,Nb,MacAddI,MacAddR))
        LTKI = resize(snd(f5(DHKeyI,~Na,Nb,MacAddI,MacAddR)), KeySizeRes)
        Ea = f6(MacKeyI,~Na,Nb,rb,IOCapabilityI,MacAddI,MacAddR)
    in
    [
        !ResDKeySize(KeySizeRes),
        State_Init_OK(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb)
    ]
    --[
        Running_Init(MacAddI,MacAddR,<'LTK',LTKI>),
        SecLTK(LTKI)
    ]->
    [
        Out(<MacAddI,MacAddR,Ea>),
        InitDSentEa(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb,MacKeyI,LTKI)
    ]

rule ResDSendEb [color=#FFF68F]:
    let
        MacKeyR = fst(f5(DHKeyR,Na,~Nb,MacAddI,MacAddR))
        LTKR = resize(snd(f5(DHKeyR,Na,~Nb,MacAddI,MacAddR)), KeySizeInit)
        Eb = f6(MacKeyR,~Nb,Na,ra,IOCapabilityR,MacAddR,MacAddI)
    in
    [
        !InitDKeySize(KeySizeInit),
        State_Res_OK(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb),
        In(<MacAddI,MacAddR,Ea>)
    ]
    --[ 
        Running_Res(MacAddR,MacAddI,<'LTK',LTKR>),
        SecLTK(LTKR),
        Eq(Ea,f6(MacKeyR,Na,~Nb,rb,IOCapabilityI,MacAddI,MacAddR)),
        Commit_Res(MacAddR,MacAddI,<'LTK',LTKR>),
        Commit_Res(MacAddR,MacAddI,<'DHKey',DHKeyR>),
        FinishedRes(),
		MP(MacAddI,MacAddR),
		LTK(MacAddR,MacAddI,LTKR),
		FSecAuthLTK(MacAddR,MacAddI,LTKR)
    ]->
    [
        Out(<MacAddR,MacAddI,Eb>),
        State_ResDAuthSta2_End(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb,LTKR)
    ]

rule InitDCheck [color=#BBFFFF]:
    [
        InitDSentEa(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb,MacKeyI,LTKI),
        In(<MacAddR,MacAddI,Eb>)
    ]
    --[ 
        Eq(Eb,f6(MacKeyI,Nb,~Na,ra,IOCapabilityR,MacAddR,MacAddI)),
        Commit_Init(MacAddI,MacAddR,<'LTK',LTKI>),
        Commit_Init(MacAddI,MacAddR,<'DHKey',DHKeyI>),
        FinishedInit(),
		MP(MacAddI,MacAddR),
		LTK(MacAddI,MacAddR,LTKI),
		FSecAuthLTK(MacAddI,MacAddR,LTKI)
    ]->
    [
        State_InitDAuthSta2_End(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb,MacKeyI,LTKI)
    ]



/*
rule InitRevealLTK [color=#BBFFFF]:
    [
        !InitDKeySize('7'),
        !LTKIGenerated(LTKI)
    ]
    --[
    ]->
    [
        Out(LTKI)
    ]

rule ResDRevealLTK [color=#FFF68F]:
    [
        !ResDKeySize('7'),
        !LTKRGenerated(LTKR)
    ]
    --[
    ]->
    [
        Out(LTKR)
    ]
*/


/*
Authentication stage 2 End ********************************************
*/

/*
Key Distribution Start ------------------------------------------
*/
rule ResDDistribution [color=#FFF68F]:
    let
        DisR = senc(<~IRKR,~BD_ADDRR,~CSRKR>,LTKR)
    in
    [
        State_ResDAuthSta2_End(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb,LTKR),
        Fr(~IRKR),
        Fr(~BD_ADDRR),
        Fr(~CSRKR)
    ]
    --[ 
    ]->
    [
        Out(<MacAddR,MacAddI,DisR>),
        State_ResDDistributed(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb,LTKR,~IRKR,~BD_ADDRR,~CSRKR)
    ]

rule InitDDistribution [color=#BBFFFF]:
    let
        DisR = senc(<IRKR,BD_ADDRR,CSRKR>,LTKI)
        DisI = senc(<~IRKI,~BD_ADDRI,~CSRKI>,LTKI)
    in
    [
        State_InitDAuthSta2_End(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb,MacKeyI,LTKI),
        In(<MacAddR,MacAddI,DisR>),
        Fr(~IRKI),
        Fr(~BD_ADDRI),
        Fr(~CSRKI)
    ]
    --[ 
    ]->
    [
        Out(<MacAddI,MacAddR,DisI>),
        State_InitDDistributedBoth(InitD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skI,DHpkR,DHKeyI,ra,rb,~Na,Nb,MacKeyI,LTKI,~IRKI,~BD_ADDRI,~CSRKI,IRKR,BD_ADDRR,CSRKR)
    ]

rule ResDRecDisI [color=#FFF68F]:
    let
        DisI = senc(<IRKI,BD_ADDRI,CSRKI>,LTKR)
    in
    [
        State_ResDDistributed(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb,LTKR,~IRKR,~BD_ADDRR,~CSRKR),
        In(<MacAddI,MacAddR,DisI>)
    ]
    --[
        Sec(IRKI)
    ]->
    [
        State_ResDDistributedBoth(ResD,MacAddI,IOCapabilityI,OOBflagI,MITMI,MacAddR,IOCapabilityR,OOBflagR,MITMR,~skR,DHpkI,DHKeyR,ra,rb,Na,~Nb,LTKR,IRKI,BD_ADDRI,CSRKI,~IRKR,~BD_ADDRR,~CSRKR)
    ]


rule oracle [color=#FFFF00]:
    let
        LTK = resize(key, '7')
    in
    [ In(senc(m,LTK)) ]
    -->
    [ Out(LTK) ] 

/*
Key Distribution End ********************************
*/

// restriction
restriction OnlyoneUser:
    "All #i #j. OnlyoneUser()@#i & OnlyoneUser()@#j ==> #i = #j"

restriction Equality:
    "All x y #i. Eq(x,y) @ i ==> x = y"

restriction Inequality:
    "All x #i. Neq(x,x) @ #i ==> F"

restriction unique:
    "All x #i #j. Unique(x) @#i & Unique(x) @#j ==> #i = #j"

divert(-1)
changequote(<!,!>)
define(IOCapabilitysToNC,<!IOCapabilitysToNC_Sub($1,$2,1,0)
    &
    IOCapabilitysToNC_Sub($1,$2,0,1)
    &
    IOCapabilitysToNC_Sub($1,$2,1,1)!>)

define(IOCapabilitysToNC_Sub,<!(All #m #n #r #s. InitD_IOCapability('$1') @m & ResD_IOCapability('$2') @n & InitD_OOBFlag('0') @r &  ResD_OOBFlag('0') @s & AFMITMI('$3') @m & AFMITMR('$4') @n ==> (Ex #p #q. (InitDNC() @p & ResDNC() @q)))!>)

define(IOCapabilitysToPE,<!IOCapabilitysToPE_Sub($1,$2,1,0)
    &
    IOCapabilitysToPE_Sub($1,$2,0,1)
    &
    IOCapabilitysToPE_Sub($1,$2,1,1)!>)

define(IOCapabilitysToPE_Sub,<!(All #m #n #r #s. InitD_IOCapability('$1') @m & ResD_IOCapability('$2') @n & InitD_OOBFlag('0') @r &  ResD_OOBFlag('0') @s & AFMITMI('$3') @m & AFMITMR('$4') @n ==> (Ex #p #q. (InitDPE() @p & ResDPE() @q)))!>)

define(OOBFlagToOOB,<!(All #m #n. InitD_OOBFlag('$1') @m & ResD_OOBFlag('$2') @n ==> (Ex #p #q. (InitDOOB() @p & ResDOOB() @q)))!>)

define(MITMFlagToJW,<!(All #m #n #s #t. InitD_OOBFlag('0') @s & ResD_OOBFlag('0') @t & AFMITMI('0') @m & AFMITMR('0') @n ==> (Ex #p #q. (InitDJW() @p & ResDJW() @q)))!>)

changequote

divert(0)dnl
lemma Executability:
    exists-trace   
	"
    ( Ex #i #j.  FinishedInit() @i & FinishedRes() @j )
    &
    OOBFlagToOOB(1,0)
    &
    OOBFlagToOOB(0,1)
    &
    OOBFlagToOOB(1,1)
    &
    MITMFlagToJW
    &
    IOCapabilitysToNC(DisplayYesNo,DisplayYesNo)
    &
    IOCapabilitysToNC(KeyboardDisplay,DisplayYesNo)
    &
    IOCapabilitysToNC(DisplayYesNo,KeyboardDisplay)
    &
    IOCapabilitysToNC(KeyboardDisplay,KeyboardDisplay)
    &
    IOCapabilitysToPE(DisplayOnly,KeyboardOnly)
    &
    IOCapabilitysToPE(DisplayYesNo,KeyboardOnly)
    &
    IOCapabilitysToPE(KeyboardDisplay,KeyboardOnly)
    &
    IOCapabilitysToPE(DisplayOnly,KeyboardDisplay)
    &
    IOCapabilitysToPE(KeyboardOnly,DisplayOnly)
    &
    IOCapabilitysToPE(KeyboardDisplay,DisplayOnly)
    &
    IOCapabilitysToPE(KeyboardOnly,DisplayYesNo)
    &
    IOCapabilitysToPE(KeyboardOnly,KeyboardOnly)
    &
    IOCapabilitysToPE(KeyboardOnly,KeyboardDisplay)
    "

predicates: A1(a,b,dhkey) <=> (All #i. Commit_Init(a,b,<'DHKey',dhkey>) @i
        ==> (Ex #j. Running_Res(b,a,<'DHKey',dhkey>) @j)
        | (Ex #k. InitDJW()@k))

predicates: A2(a,b,dhkey) <=> (All #i. Commit_Res(a,b,<'DHKey',dhkey>) @i
        ==> (Ex #j. Running_Init(b,a,<'DHKey',dhkey>) @j)
        | (Ex #k. ResDJW()@k))

predicates: A3(a,b,ltk) <=> (All #i. Commit_Init(a,b,<'LTK',ltk>) @i
        ==> (Ex #j. Running_Res(b,a,<'LTK',ltk>) @j)
        | (Ex #k. InitDJW()@k))

predicates: A4(a,b,ltk) <=> (All #i. Commit_Res(a,b,<'LTK',ltk>) @i
        ==> (Ex #j. Running_Init(b,a,<'LTK',ltk>) @j)
        | (Ex #k. ResDJW()@k))

predicates: A5(a,b,ltk) <=> (All #i. Commit_Init(a,b,<'LTK',ltk>) @i
        ==> (Ex #j. Running_Res(b,a,<'LTK',ltk>) @j))

predicates: A6(a,b,ltk) <=> (All #i. Commit_Res(a,b,<'LTK',ltk>) @i
        ==> (Ex #j. Running_Init(b,a,<'LTK',ltk>) @j))

lemma IAuthRwithDHKey:
  "All I R DHKey. A1(I,R,DHKey)"

lemma RAuthIwithDHKey:
  "All I R DHKey. A2(R,I,DHKey)"

lemma IAuthRwithLTK:
  "All I R LTK. A3(I,R,LTK)"

lemma RAuthIwithLTK:
  "All I R LTK. A4(I,R,LTK)"


lemma MITMP:
    "
    All I R #i. MP(I,R)@i ==> not (Ex LTKI LTKR #t1 #t2. not(A3(I,R,LTKI)) & not(A4(R,I,LTKR)) & K(LTKI)@t1 & K(LTKR)@t2)
    "

lemma LTKCP:
  "
    All I R LTKI LTKR #i #j. LTK(I,R,LTKI)@i & LTK(R,I,LTKR)@j ==> not (not(A3(I,R,LTKI)) & not(A4(R,I,LTKR)) & not(Ex #t1 #t2. K(LTKI)@t1 & K(LTKR)@t2))
  "

lemma SecAuthLTK:
  "
  All I R LTK #i #j. FSecAuthLTK(I,R,LTK)@i & FSecAuthLTK(R,I,LTK)@j ==> (A5(I,R,LTK) & A6(R,I,LTK) ==> not (Ex #k. K(LTK)@k))
  "


end

