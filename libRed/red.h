#ifndef LIB_RED_H
#define LIB_RED_H

/* The Red semantic version number components */
#define RED_VERSION_MAJOR 1
#define RED_VERSION_MINOR 0
#define RED_VERSION_PATCH 0

/* A human-friendly string representation of the version */
#define RED_VERSION_STRING "1.0.0"

/*
** A monotonically increasing numeric representation of the version number. Use
** this if you want to do range checks over versions.
*/
#define RED_VERSION_NUMBER (RED_VERSION_MAJOR * 1000000 + \
                             RED_VERSION_MINOR * 1000 + \
                             RED_VERSION_PATCH)

/* Forces the use of Visual Styles if compiling with VisualStudio */
#ifdef _MSC_VER
	#pragma comment(linker,"\"/manifestdependency:type='win32' \
	name='Microsoft.Windows.Common-Controls' version='6.0.0.0' \
	processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")
#endif

#ifdef __cplusplus
#define EXTERN_C extern "C" {
#define EXTERN_C_END }
#else
#define EXTERN_C
#define EXTERN_C_END
#endif

typedef void*     red_value;
typedef red_value red_unset;
typedef red_value red_datatype;
typedef red_value red_none;
typedef red_value red_logic;
typedef red_value red_integer;
typedef red_value red_float;
typedef red_value red_pair;
typedef red_value red_tuple;
typedef red_value red_string;
typedef red_value red_word;
typedef red_value red_block;
typedef red_value red_path;
typedef red_value red_series;
typedef red_value red_error;

EXTERN_C
/* Setup and terminate */
	void		redOpen(void);
	void		redClose(void);

/* Run Red code */
	red_value	redDo(const char* source);
	red_value	redDoFile(const char* file);
	red_value	redDoBlock(red_block code);
	red_value	redCall(red_word name, ...);

/* Expose a C callback in Red */
	red_value	redRoutine(red_word name, const char* spec, void* func_ptr);

/* C -> Red */
	long		redSymbol(const char* word);
	red_unset	redUnset(void);
	red_none	redNone(void);
	red_logic	redLogic(long logic);
	red_datatype redDatatype(long type);
	red_integer	redInteger(long number);
	red_float	redFloat(double number);
	red_pair	redPair(long x, long y);
	red_tuple	redTuple(long r, long g, long b);
	red_tuple	redTuple4(long r, long g, long b, long a);
	red_string	redString(const char* string);
	red_word	redWord(const char* word);
	red_block	redBlock(red_value v, ...);
	red_path	redPath(red_value v, ...);
	red_path	redLoadPath(const char* path);
	red_value	redMakeSeries(unsigned long type, unsigned long slots);

/* Red -> C */
	long		redCInt32(red_integer number);
	double		redCDouble(red_float number);
	const char*	redCString(red_string string);
	long		redTypeOf(red_value value);

/* Red actions */
	red_value	redAppend(red_series series, red_value value);
	red_value	redChange(red_series series, red_value value);
	red_value	redClear(red_series series);
	red_value	redCopy(red_value value);
	red_value	redFind(red_series series, red_value value);
	red_value	redIndex(red_series series);
	red_value	redLength(red_series series);
	red_value	redMake(red_value proto, red_value spec);
	red_value	redMold(red_value value);
	red_value	redPick(red_series series, red_value value);
	red_value	redPoke(red_series series, red_value index, red_value value);
	red_value	redPut(red_series series, red_value index, red_value value);
	red_value	redRemove(red_series series);
	red_value	redSelect(red_series series, red_value value);
	red_value	redSkip(red_series series, red_integer offset);
	red_value	redTo(red_value proto, red_value spec);

/* Access to a Red global word */
	red_value	redSet(long id, red_value value);
	red_value	redGet(long id);

/* Access to a Red path */
	red_value	redSetPath(red_path path, red_value value);
	red_value	redGetPath(red_path path);

/* Debugging */
	void		redPrint(red_value value);
	red_value	redProbe(red_value value);
	red_value	redHasError(void);
	const char*	redFormError(void);
	int			redOpenLogWindow(void);
	int			redCloseLogWindow(void);
	void		redOpenLogFile(const char *name);
	void		redCloseLogFile(void);
EXTERN_C_END

/* Red Types */
typedef enum
{
	RED_TYPE_VALUE,
	RED_TYPE_DATATYPE,
	RED_TYPE_UNSET,
	RED_TYPE_NONE,
	RED_TYPE_LOGIC,
	RED_TYPE_BLOCK,
	RED_TYPE_PAREN,
	RED_TYPE_STRING,
	RED_TYPE_FILE,
	RED_TYPE_URL,
	RED_TYPE_CHAR,
	RED_TYPE_INTEGER,
	RED_TYPE_FLOAT,
	RED_TYPE_SYMBOL,
	RED_TYPE_CONTEXT,
	RED_TYPE_WORD,
	RED_TYPE_SET_WORD,
	RED_TYPE_LIT_WORD,
	RED_TYPE_GET_WORD,
	RED_TYPE_REFINEMENT,
	RED_TYPE_ISSUE,
	RED_TYPE_NATIVE,
	RED_TYPE_ACTION,
	RED_TYPE_OP,
	RED_TYPE_FUNCTION,
	RED_TYPE_PATH,
	RED_TYPE_LIT_PATH,
	RED_TYPE_SET_PATH,
	RED_TYPE_GET_PATH,
	RED_TYPE_ROUTINE,
	RED_TYPE_BITSET,
	RED_TYPE_POINT,
	RED_TYPE_OBJECT,
	RED_TYPE_TYPESET,
	RED_TYPE_ERROR,
	RED_TYPE_VECTOR,
	RED_TYPE_HASH,
	RED_TYPE_PAIR,
	RED_TYPE_PERCENT,
	RED_TYPE_TUPLE,
	RED_TYPE_MAP,
	RED_TYPE_BINARY,
	RED_TYPE_SERIES,
	RED_TYPE_TIME,
	RED_TYPE_TAG,
	RED_TYPE_EMAIL,
	RED_TYPE_IMAGE,
	RED_TYPE_EVENT
	// RED_TYPE_CLOSURE,
	// RED_TYPE_PORT
} RedType;

#endif