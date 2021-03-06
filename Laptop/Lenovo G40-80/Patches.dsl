# Includes battery aptch from RehabMan and brightness key patch

# Battery Patch
# disable BAT1 device
into method label _STA parent_label BAT1 replace_content begin Return (Zero) end;

into method label B1B2 remove_entry;
into definitionblock code_regex . insert
begin
Method (B1B2, 2, NotSerialized) { Return(Or(Arg0, ShiftLeft(Arg1, 8))) }\n
end;

#                        B1RC,   16, 
#                        B1FV,   16, 
#                        B1DC,   16, 
#                        B1DV,   16,
#                        B1FC,   16,
#                        B1AC,   16,

# 16-bit registers
into device label EC0 code_regex B1RC,\s+16 replace_matched begin CA00,8,CA01,8 end;
into device label EC0 code_regex B1FV,\s+16 replace_matched begin CB00,8,CB01,8 end;
into device label EC0 code_regex B1DC,\s+16 replace_matched begin CD00,8,CD01,8 end;
into device label EC0 code_regex B1DV,\s+16 replace_matched begin CE00,8,CE01,8 end;
into device label EC0 code_regex B1FC,\s+16 replace_matched begin CF00,8,CF01,8 end;
into device label EC0 code_regex B1AC,\s+16 replace_matched begin CG00,8,CG01,8 end;

# fix 16-bit methods
into method label _BST code_regex \(B1RC, replaceall_matched begin (B1B2(CA00,CA01), end;
into method label _BST code_regex \(B1FV, replaceall_matched begin (B1B2(CB00,CB01), end;
into method label _BIF code_regex \(B1DC, replaceall_matched begin (B1B2(CD00,CD01), end;
into method label _BIF code_regex \(B1DV, replaceall_matched begin (B1B2(CE00,CE01), end;
into method label _BIF code_regex \(B1FC, replaceall_matched begin (B1B2(CF00,CF01), end;
into method label _BST code_regex \(B1AC, replaceall_matched begin (B1B2(CG00,CG01), end;

# fix 16-bit methods SMTF (Lenovo G40-80)
into method label SMTF code_regex \(B1RC, replaceall_matched begin (B1B2(CA00,CA01), end;
into method label SMTF code_regex \(B1FV, replaceall_matched begin (B1B2(CB00,CB01), end;
into method label SMTF code_regex \(B1DC, replaceall_matched begin (B1B2(CD00,CD01), end;
into method label SMTF code_regex \(B1DV, replaceall_matched begin (B1B2(CE00,CE01), end;
into method label SMTF code_regex \(B1FC, replaceall_matched begin (B1B2(CF00,CF01), end;
into method label SMTF code_regex \(B1AC, replaceall_matched begin (B1B2(CG00,CG01), end;

#                        FWBT,   64,
#                        SMDA,   256, 

# deal with buffer fields above
into device label EC0 code_regex (FWBT,)\s+(64) replace_matched begin WBTX,%2,//%1%2 end;
into device label EC0 code_regex (SMDA,)\s+(256) replace_matched begin MDAX,%2,//%1%2 end;


#Field (ERAM, ByteAcc, Lock, Preserve)
#                    {                          
#                           Offset (0x12), 
#                        FUSL,   8, //(0x12)
#                        FUSH,   8, //(0x13) 
#                        FWBT,64, //!!(0x14)
#                        Offset (0x5D), 
#                        EXSI,   8, //(0x5d)
#                        EXSB,   8, //(0x5e)
#                        EXND,   8, //(0x5f)
#                        SMPR,   8, //(0x60)
#                        SMST,   8, //(0x61)
#                        SMAD,   8, //(0x62)
#                        SMCM,   8, //(0x63)
#                        SMDA,256,//!!(0x64) 


# utility methods to read/write buffers from/to EC
into method label RE1B parent_label EC0 remove_entry;
into method label RECB parent_label EC0 remove_entry;
into device label EC0 insert
begin
Method (RE1B, 1, NotSerialized)\n
{\n
    OperationRegion(ERAM, EmbeddedControl, Arg0, 1)\n
    Field(ERAM, ByteAcc, NoLock, Preserve) { BYTE, 8 }\n
    Return(BYTE)\n
}\n
Method (RECB, 2, Serialized)\n
// Arg0 - offset in bytes from zero-based EC\n
// Arg1 - size of buffer in bits\n
{\n
    ShiftRight(Arg1, 3, Arg1)\n
    Name(TEMP, Buffer(Arg1) { })\n
    Add(Arg0, Arg1, Arg1)\n
    Store(0, Local0)\n
    While (LLess(Arg0, Arg1))\n
    {\n
        Store(RE1B(Arg0), Index(TEMP, Local0))\n
        Increment(Arg0)\n
        Increment(Local0)\n
    }\n
    Return(TEMP)\n
}\n
end;

into method label MHIF code_regex \(FWBT, replaceall_matched begin (RECB(0x14,64), end;
into method label GBID code_regex \(FWBT, replaceall_matched begin (RECB(0x14,64), end;


into method label WE1B parent_label EC0 remove_entry;
into method label WECB parent_label EC0 remove_entry;
into device label EC0 insert
begin
Method (WE1B, 2, NotSerialized)\n
{\n
    OperationRegion(ERAM, EmbeddedControl, Arg0, 1)\n
    Field(ERAM, ByteAcc, NoLock, Preserve) { BYTE, 8 }\n
    Store(Arg1, BYTE)\n
}\n
Method (WECB, 3, Serialized)\n
// Arg0 - offset in bytes from zero-based EC\n
// Arg1 - size of buffer in bits\n
// Arg2 - value to write\n
{\n
    ShiftRight(Arg1, 3, Arg1)\n
    Name(TEMP, Buffer(Arg1) { })\n
    Store(Arg2, TEMP)\n
    Add(Arg0, Arg1, Arg1)\n
    Store(0, Local0)\n
    While (LLess(Arg0, Arg1))\n
    {\n
        WE1B(Arg0, DerefOf(Index(TEMP, Local0)))\n
        Increment(Arg0)\n
        Increment(Local0)\n
    }\n
}\n
end;

into method label MHPF code_regex \(SMDA, replaceall_matched begin (RECB(0x64,256), end;
into method label CFUN code_regex \(SMDA, replaceall_matched begin (RECB(0x64,256), end; 
into method label MHPF code_regex Store\s+\((.*),\s+SMDA\) replaceall_matched begin WECB(0x64,256,%1) end;
into method label CFUN code_regex Store\s+\((.*),\s+SMDA\) replaceall_matched begin WECB(0x64,256,%1) end;

# Brightness key patch
into method label _Q11 replace_content
begin
// Brightness Down\n
    Notify(\_SB.PCI0.LPCB.PS2K, 0x0405)\n
end;
into method label _Q12 replace_content
begin
// Brightness Up\n
    Notify(\_SB.PCI0.LPCB.PS2K, 0x0406)\n
end;
