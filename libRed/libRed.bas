Attribute VB_Name = "libRed"
'=== LibRed imports ===

Private callBlkWord As Long
Private blkWord As Long

Public Enum RedTypes
    red_value
    red_datatype
    red_unset
    red_none
    red_logic
    red_block
    red_paren
    red_string
    red_file
    red_url
    red_char
    red_integer
    red_float
    red_symbol
    red_context
    red_word
    red_set_word
    red_lit_word
    red_get_word
    red_refinement
    red_issue
    red_native
    red_action
    red_op
    red_function
    red_path
    red_lit_path
    red_set_path
    red_get_path
    red_routine
    red_bitset
    red_point
    red_object
    red_typeset
    red_error
    red_vector
    red_hash
    red_pair
    red_percent
    red_tuple
    red_map
    red_binary
    red_series
    red_time
    red_tag
    red_email
    red_image
    red_event
End Enum

Public Enum RedEncodings
    reUTF8 = 1
    reUTF16
    reVARIANT
End Enum

'--- Setup and terminate ---
Public Declare Sub redOpenReal Lib "libRed.dll" Alias "redOpen" ()

'--- Run Red code ---
Public Declare Function redDo Lib "libRed.dll" (ByRef source As Variant) As Long
Public Declare Function redDoFile Lib "libRed.dll" (ByRef file As Variant) As Long
Public Declare Function redDoBlock Lib "libRed.dll" (ByVal code As Long) As Long

'--- Expose a VB callback in Red ---
Public Declare Function redRoutine Lib "libRed.dll" (ByVal name As Long, ByRef desc As Variant, ByVal ptr As Long) As Long

'--- VB -> Red ---
Public Declare Function redSymbol Lib "libRed.dll" (ByRef word As Variant) As Long
Public Declare Function redUnset Lib "libRed.dll" () As Long
Public Declare Function redNone Lib "libRed.dll" () As Long
Public Declare Function redLogicReal Lib "libRed.dll" Alias "redLogic" (ByVal bool As Long) As Long
Public Declare Function redDatatype Lib "libRed.dll" (ByVal dtype As Long) As Long
Public Declare Function redInteger Lib "libRed.dll" (ByVal number As Long) As Long
Public Declare Function redFloat Lib "libRed.dll" (ByVal number As Double) As Long
Public Declare Function redPair Lib "libRed.dll" (ByVal x As Long, ByVal y As Long) As Long
Public Declare Function redTuple Lib "libRed.dll" (ByVal r As Long, ByVal g As Long, ByVal b As Long) As Long
Public Declare Function redTuple4 Lib "libRed.dll" (ByVal r As Long, ByVal g As Long, ByVal b As Long, ByVal a As Long) As Long
Public Declare Function redString Lib "libRed.dll" (ByRef str As Variant) As Long
Public Declare Function redWord Lib "libRed.dll" (ByRef word As Variant) As Long
Public Declare Function redMakeSeries Lib "libRed.dll" (ByVal t As Long, ByVal size As Long) As Long

'--- Red -> VB ---
Public Declare Function redCInt32 Lib "libRed.dll" (ByVal value As Long) As Long
Public Declare Function redCDouble Lib "libRed.dll" (ByVal value As Long) As Double
Public Declare Function redTypeOf Lib "libRed.dll" (ByVal value As Long) As Long
Public Declare Sub redVString Lib "libRed.dll" (ByVal str As Long, ByRef varg As Variant)

'--- Red actions ---
Public Declare Function redAppend Lib "libRed.dll" (ByVal series As Long, ByVal value As Long) As Long
Public Declare Function redClear Lib "libRed.dll" (ByVal series As Long) As Long
Public Declare Function redCopy Lib "libRed.dll" (ByVal value As Long) As Long
Public Declare Function redFind Lib "libRed.dll" (ByVal series As Long, ByVal value As Long) As Long
Public Declare Function redIndex Lib "libRed.dll" (ByVal series As Long) As Long
Public Declare Function redLength Lib "libRed.dll" (ByVal series As Long) As Long
Public Declare Function redMake Lib "libRed.dll" (ByVal proto As Long, ByVal spec As Long) As Long
Public Declare Function redMold Lib "libRed.dll" (ByVal value As Long) As Long
Public Declare Function redPick Lib "libRed.dll" (ByVal series As Long, ByVal index As Long) As Long
Public Declare Function redPoke Lib "libRed.dll" (ByVal series As Long, ByVal index As Long, ByVal value As Long) As Long
Public Declare Function redPut Lib "libRed.dll" (ByVal series As Long, ByVal index As Long, ByVal value As Long) As Long
Public Declare Function redRemove Lib "libRed.dll" (ByVal series As Long) As Long
Public Declare Function redSelect Lib "libRed.dll" (ByVal series As Long, ByVal value As Long) As Long
Public Declare Function redSkip Lib "libRed.dll" (ByVal series As Long, ByVal offset As Long) As Long
Public Declare Function redTo Lib "libRed.dll" (ByVal proto As Long, ByVal spec As Long) As Long

'--- Access to a Red global word ---
Public Declare Function redSet Lib "libRed.dll" (ByVal id As Long, ByVal value As Long) As Long
Public Declare Function redGet Lib "libRed.dll" (ByVal id As Long) As Long

'--- Access to a Red path ---
Public Declare Function redSetPath Lib "libRed.dll" (ByVal path As Long, ByVal value As Long) As Long
Public Declare Function redGetPath Lib "libRed.dll" (ByVal path As Long) As Long

'--- libRed settings ---
Public Declare Sub redSetEncoding Lib "libRed.dll" (ByVal encIn As Long, ByVal encOut As Long)

'--- Debugging purpose ---
Public Declare Function redPrint Lib "libRed.dll" (ByVal value As Long)
Public Declare Function redProbe Lib "libRed.dll" (ByVal value As Long) As Long
Public Declare Function redHasError Lib "libRed.dll" () As Long
Public Declare Function redOpenLogWindow Lib "libRed.dll" () As Long
Public Declare Function redCloseLogWindow Lib "libRed.dll" () As Long
Public Declare Sub redOpenLogFile Lib "libRed.dll" (ByVal name As String)
Public Declare Sub redCloseLogFile Lib "libRed.dll" ()


'--- libRed VB-specific wrappers ---

Public Sub redOpen()
    redOpenReal
    redSetEncoding reVARIANT, reVARIANT
    
    callBlkWord = redSymbol("VBCallBlk")
    redSet callBlkWord, redMakeSeries(red_block, 10)
    blkWord = redSymbol("blk")
End Sub
Public Function redCString(str As Long)
    Dim var
    var = ""
    redVString str, var
    redCString = var
End Function

Public Sub redClose()
    'Do nothing for now
End Sub

Public Function redLogic(bool As Boolean) As Long
    redLogic = redLogicReal(IIf(bool, 1, 0))
End Function

Private Sub redAppendBlockValue(blk As Long, value As Variant, asWord As Boolean)
    Select Case VarType(value)
        Case vbInteger, vbLong: redAppend redGet(blk), redInteger(CLng(value))
        Case vbSingle, vbDouble: redAppend redGet(blk), redFloat(CDbl(value))
        Case vbString: redAppend redGet(blk), IIf(asWord, redWord(CVar(value)), redString(CVar(value)))
        Case Else:     MsgBox "redAppendBlockValue: Unsupported type"
    End Select
End Sub

Public Function redBlock(ParamArray args() As Variant) As Long
    Dim i As Long
    Dim blk As Long
    
    blk = blkWord
    redSet blk, redMakeSeries(red_block, UBound(args) - LBound(args) + 1)
    For i = LBound(args) To UBound(args): redAppend redGet(blk), args(i): Next i
    redBlock = redGet(blk)
End Function

Public Function redPath(ParamArray args() As Variant) As Long
    Dim i As Long
    Dim blk As Long
    
    blk = blkWord
    redSet blk, redMakeSeries(red_path, UBound(args) - LBound(args) + 1)
    For i = LBound(args) To UBound(args): redAppend redGet(blk), args(i), True: Next i
    redPath = redGet(blk)
End Function

Public Function redCall(ParamArray args() As Variant) As Long
    Dim i As Long
    Dim blk As Long
    
    blk = callBlkWord
    redClear redGet(blk)
    redAppend redGet(blk), args(0)
    For i = LBound(args) + 1 To UBound(args): redAppend redGet(blk), args(i), False: Next i
    redCall = redDoBlock(redGet(blk))
End Function

Public Function redBlockVB(ParamArray args() As Variant) As Long
    Dim i As Long
    Dim blk As Long
    
    blk = blkWord
    redSet blk, redMakeSeries(red_block, UBound(args) - LBound(args) + 1)
    For i = LBound(args) To UBound(args): redAppendBlockValue blk, args(i), False: Next i
    redBlockVB = redGet(blk)
End Function

Public Function redPathVB(ParamArray args() As Variant) As Long
    Dim i As Long
    Dim blk As Long
    
    blk = blkWord
    redSet blk, redMakeSeries(red_path, UBound(args) - LBound(args) + 1)
    For i = LBound(args) To UBound(args): redAppendBlockValue blk, args(i), True: Next i
    redPathVB = redGet(blk)
End Function

Public Function redCallVB(ParamArray args() As Variant) As Long
    Dim i As Long
    Dim blk As Long
    
    If VarType(args(0)) <> vbString Then
        MsgBox "Error in redCallVB(), first argument must be a string"
        redCallVB = redUnset
    End If
    blk = callBlkWord
    redClear redGet(blk)
    redAppend redGet(blk), redWord(CVar(args(0)))
    For i = LBound(args) + 1 To UBound(args): redAppendBlockValue blk, args(i), False: Next i
    redCallVB = redDoBlock(redGet(blk))
End Function
