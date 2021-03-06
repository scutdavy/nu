/*!
 @file Nu.m
 @description Nu.
 @copyright Copyright (c) 2007-2011 Radtastical Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#define NU_VERSION "2.0.1"
#define NU_VERSION_MAJOR 2
#define NU_VERSION_MINOR 0
#define NU_VERSION_TWEAK 1
#define NU_RELEASE_DATE "2011-09-02"
#define NU_RELEASE_YEAR  2011
#define NU_RELEASE_MONTH 09
#define NU_RELEASE_DAY   02

#import <AvailabilityMacros.h>
#import <Foundation/Foundation.h>
#import <unistd.h>

#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#define NSRect CGRect
#define NSPoint CGPoint
#define NSSize CGSize
#endif

#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <stdint.h>
#import <math.h>
#import <time.h>
#import <sys/stat.h>
#import <sys/mman.h>

#import <mach/mach.h>
#import <mach/mach_time.h>

#if !TARGET_OS_IPHONE
#import <readline/readline.h>
#import <readline/history.h>
#endif

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_IPHONE
#import "ffi.h"
#else
#import "ffi/ffi.h"
#endif

#import <dlfcn.h>

#import "Nu.h"

#define IS_NOT_NULL(xyz) ((xyz) && (((id) (xyz)) != [NSNull null]))

// We'd like for this to be in the ObjC2 API, but it isn't.
static void nu_class_addInstanceVariable_withSignature(Class thisClass, const char *variableName, const char *signature);

// These are handy.
static IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
static BOOL nu_copyInstanceMethod(Class destinationClass, Class sourceClass, SEL selector);
static BOOL nu_objectIsKindOfClass(id object, Class class);
static void nu_markEndOfObjCTypeString(char *type, size_t len);

// This makes it safe to insert nil into container classes
static void nu_swizzleContainerClasses(void);

static id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block);
static id nu_calling_objc_method_handler(id target, Method m, NSMutableArray *args);
static id get_nu_value_from_objc_value(void *objc_value, const char *typeString);
static int set_objc_value_from_nu_value(void *objc_value, id nu_value, const char *typeString);
static void *value_buffer_for_objc_type(const char *typeString);
static NSString *signature_for_identifier(NuCell *cell, NuSymbolTable *symbolTable);
static id help_add_method_to_class(Class classToExtend, id cdr, NSMutableDictionary *context, BOOL addClassMethod);
static size_t size_of_objc_type(const char *typeString);

#pragma mark - nu null
@interface NSNull(nu_null)
+ (id) NU_null;
@end

@implementation NSNull (nu_null)
+ (id) NU_null{
    return [NSNull null];
}
@end


#pragma mark - NuHandler.h

struct nu_handler_description{
    IMP handler;
    char **description;
};

/*!
 @class NuHandlerWarehouse
 @abstract Internal class used to store and vend method implementations on platforms that don't allow them to be constructed at runtime.
 */
@interface NuHandlerWarehouse : NSObject
+ (void) registerHandlers:(struct nu_handler_description *) description withCount:(int) count forReturnType:(NSString *) returnType;
+ (IMP) handlerWithSelector:(SEL)sel block:(NuBlock *)block signature:(const char *) signature userdata:(char **) userdata;
@end

static void nu_handler(void *return_value,
                       struct nu_handler_description *description,
                       id receiver,
                       va_list ap);


#pragma mark - NuInternals.h

// Execution contexts are NSMutableDictionaries that are keyed by
// symbols.  Here we define two string keys that allow us to store
// some extra information in our contexts.

// Use this key to get the symbol table from an execution context.
#define SYMBOLS_KEY @"symbols"

// Use this key to get the parent context of an execution context.
#define PARENT_KEY @"parent"

@interface NSMutableDictionary (nu_true_symbol)
- (id) NU_true;
- (id) NU_false;
@end

@implementation NSMutableDictionary (nu_true_symbol)
- (id) NU_true{
    NuSymbolTable *symbolTable = [self objectForKey:SYMBOLS_KEY];
    return [symbolTable symbolWithString:@"t"];
}

- (id) NU_false{
    return [NSNull NU_null];
}
@end

/*!
 @class NuBreakException
 @abstract Internal class used to implement the Nu break operator.
 */
@interface NuBreakException : NSException
@end

/*!
 @class NuContinueException
 @abstract Internal class used to implement the Nu continue operator.
 */
@interface NuContinueException : NSException
@end

/*!
 @class NuReturnException
 @abstract Internal class used to implement the Nu return operator.
 */
@interface NuReturnException : NSException{
    id _value;
	id _blockForReturn;
}

- (id) value;
- (id) blockForReturn;
@end

// use this to test a value for "truth"
static bool nu_valueIsTrue(id value);

// use this to get the filename for a NuCell created by the parser
static const char *nu_parsedFilename(int i);

#pragma mark - DTrace macros

/*
 * Generated by dtrace(1M).
 */

#ifndef	_DTRACE_H
#define	_DTRACE_H

#include <unistd.h>

#ifdef	__cplusplus
extern "C" {
#endif
    
#define NU_STABILITY "___dtrace_stability$nu$v1$5_5_5_1_1_5_1_1_5_5_5_5_5_5_5"
    
#define NU_TYPEDEFS "___dtrace_typedefs$nu$v1"
    
#define	NU_LIST_EVAL_BEGIN(arg0, arg1) \
{ \
__asm__ volatile(".reference " NU_TYPEDEFS); \
__dtrace_probe$nu$list_eval_begin$v1$63686172202a$696e74((char *)arg0, arg1); \
__asm__ volatile(".reference " NU_STABILITY); \
}
#define	NU_LIST_EVAL_BEGIN_ENABLED() \
__dtrace_isenabled$nu$list_eval_begin$v1()
#define	NU_LIST_EVAL_END(arg0, arg1) \
{ \
__asm__ volatile(".reference " NU_TYPEDEFS); \
__dtrace_probe$nu$list_eval_end$v1$63686172202a$696e74((char *)arg0, arg1); \
__asm__ volatile(".reference " NU_STABILITY); \
}
#define	NU_LIST_EVAL_END_ENABLED() \
__dtrace_isenabled$nu$list_eval_end$v1()
    
    
    extern void __dtrace_probe$nu$list_eval_begin$v1$63686172202a$696e74(char *, int);
    extern int __dtrace_isenabled$nu$list_eval_begin$v1(void);
    extern void __dtrace_probe$nu$list_eval_end$v1$63686172202a$696e74(char *, int);
    extern int __dtrace_isenabled$nu$list_eval_end$v1(void);
    
#ifdef	__cplusplus
}
#endif

#endif	/* _DTRACE_H */

#pragma mark - NuMain

static bool nu_valueIsTrue(id value) {
    bool result = value && (value != [NSNull null]);
    if (result && nu_objectIsKindOfClass(value, [NSNumber class])) {
        if ([value doubleValue] == 0.0)
            result = false;
    }
    return result;
}

@interface NuApplication : NSObject {
    NSMutableArray *arguments;
}

@end

@implementation NuApplication

+ (NuApplication *) sharedApplication{
    static NuApplication *_sharedApplication = 0;
    if (!_sharedApplication)
        _sharedApplication = [[NuApplication alloc] init];
    return _sharedApplication;
}

- (void) setArgc:(int) argc argv:(const char *[])argv startingAtIndex:(int) start{
    arguments = [[NSMutableArray alloc] init];
    int i;
    for (i = start; i < argc; i++) {
        [arguments addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
    }
}

- (NSArray *) arguments{
    return arguments;
}

@end

int NuMain(int argc, const char *argv[]){
    @autoreleasepool {
        NuInit();
        
        @try
        {
            // first we try to load main.nu from the application bundle.
            NSString *main_path = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"nu"];
            if (main_path) {
                NSString *main_nu = [NSString stringWithContentsOfFile:main_path encoding:NSUTF8StringEncoding error:nil];
                if (main_nu) {
                    NuParser *parser = [Nu sharedParser];
                    id script = [parser parse:main_nu asIfFromFilename:[main_nu cStringUsingEncoding:NSUTF8StringEncoding]];
                    [parser eval:script];
                    [parser release];
                    return 0;
                }
            }
            // if that doesn't work, use the arguments to decide what to execute
            else if (argc > 1) {
                NuParser *parser = [Nu sharedParser];
                id script, result;
                bool didSomething = false;
                bool goInteractive = false;
                int i = 1;
                bool fileEvaluated = false;           // only evaluate one filename
                while ((i < argc) && !fileEvaluated) {
                    if (!strcmp(argv[i], "-e")) {
                        i++;
                        script = [parser parse:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
                        result = [parser eval:script];
                        didSomething = true;
                    }
                    else if (!strcmp(argv[i], "-f")) {
                        i++;
                        script = [parser parse:[NSString stringWithFormat:@"(load \"%s\")", argv[i]] asIfFromFilename:argv[i]];
                        result = [parser eval:script];
                    }
                    else if (!strcmp(argv[i], "-v")) {
                        printf("Nu %s (%s)\n", NU_VERSION, NU_RELEASE_DATE);
                        didSomething = true;
                    }
                    else if (!strcmp(argv[i], "-i")) {
                        goInteractive = true;
                    }
                    else {
                        // collect the command-line arguments
                        [[NuApplication sharedApplication] setArgc:argc argv:argv startingAtIndex:i+1];
                        id string = [NSString stringWithContentsOfFile:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding] encoding:NSUTF8StringEncoding error:NULL];
                        if (string) {
                            id script = [parser parse:string asIfFromFilename:argv[i]];
                            [parser eval:script];
                            fileEvaluated = true;
                        }
                        else {
                            // complain somehow. Throw an exception?
                            NSLog(@"Error: can't open file named %s", argv[i]);
                        }
                        didSomething = true;
                    }
                    i++;
                }
#if !TARGET_OS_IPHONE
                if (!didSomething || goInteractive)
                    [parser interact];
#endif
                [parser release];
                return 0;
            }
            // if there's no file, run at the terminal
            else {
                if (!isatty(stdin->_file))
                {
                    NuParser *parser = [Nu sharedParser];
                    id string = [[NSString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
                    id script = [parser parse:string asIfFromFilename:"stdin"];
                    [parser eval:script];
                    [parser release];
                }
                else {
#if !TARGET_OS_IPHONE
                    return [NuParser main];
#endif
                }
            }
        }
        @catch (NuException* nuException)
        {
            printf("%s\n", [[nuException dump] cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        @catch (id exception)
        {
            NSLog(@"Terminating due to uncaught exception (below):");
            NSLog(@"%@: %@", [exception name], [exception reason]);
        }
        
    }
    return 0;
}

static void transplant_nu_methods(Class destination, Class source){
    if (!nu_copyInstanceMethod(destination, source, @selector(evalWithArguments:context:)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(sendMessage:withContext:)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(stringValue)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(evalWithContext:)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(handleUnknownMessage:withContext:)))
        NSLog(@"method copy failed");
}

void NuInit(){
    static BOOL initialized = NO;
    if (initialized) {
        return;
    }
    initialized = YES;
    @autoreleasepool {
        // as a convenience, we set a file static variable to nil.
        // add enumeration to collection classes
        [NSArray include: [NuClass classWithClass:[NuEnumerable class]]];
        [NSSet include: [NuClass classWithClass:[NuEnumerable class]]];
        [NSString include: [NuClass classWithClass:[NuEnumerable class]]];
        
        // Copy some useful methods from NSObject to NSProxy.
        // Their implementations are identical; this avoids code duplication.
        transplant_nu_methods([NSProxy class], [NSObject class]);
        
        
#if !defined(MININUSH) && !TARGET_OS_IPHONE
        // Load some standard files
        [Nu loadNuFile:@"nu"            fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"bridgesupport" fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"cocoa"         fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"help"          fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
#endif
    }
}

// Helpers for programmatic construction of Nu code.

id _nunull(){
    return [NSNull null];
}

id _nustring(const unsigned char *string){
    return [NSString stringWithCString:(const char *) string encoding:NSUTF8StringEncoding];
}

id _nustring_with_length(const unsigned char *string, int length){
	NSData *data = [NSData dataWithBytes:string length:length];
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

id _nudata(const void *bytes, int length){
	return [NSData dataWithBytes:bytes length:length];
}

id _nusymbol(const unsigned char *cstring){
    return [[NuSymbolTable sharedSymbolTable] symbolWithString:_nustring(cstring)];
}

id _nusymbol_with_length(const unsigned char *string, int length){
	return [[NuSymbolTable sharedSymbolTable] symbolWithString:_nustring_with_length(string, length)];
}

id _nunumberd(double d){
    return [NSNumber numberWithDouble:d];
}

id _nucell(id car, id cdr){
    return [NuCell cellWithCar:car cdr:cdr];
}

id _nuregex(const unsigned char *pattern, int options){
    return [NSRegularExpression regexWithPattern:_nustring(pattern) options:options];
}

id _nuregex_with_length(const unsigned char *pattern, int length, int options){
    return [NSRegularExpression regexWithPattern:_nustring_with_length(pattern, length) options:options];
}

id _nulist(id firstObject, ...){
    id list = nil;
    id eachObject;
    va_list argumentList;
    if (firstObject) {
        // The first argument isn't part of the varargs list,
        // so we'll handle it separately.
        list = [[[NuCell alloc] init] autorelease];
        [list setCar:firstObject];
        id cursor = list;
        va_start(argumentList, firstObject);
        // Start scanning for arguments after firstObject.
        // As many times as we can get an argument of type "id"
        // that isn't nil, add it to self's contents.
        while ((eachObject = va_arg(argumentList, id))) {
            [cursor setCdr:[[[NuCell alloc] init] autorelease]];
            cursor = [cursor cdr];
            [cursor setCar:eachObject];
        }
        va_end(argumentList);
    }
    return list;
}

@implementation Nu
+ (NuParser *) parser{
    return [[[NuParser alloc] init] autorelease];
}

+ (NuParser *) sharedParser{
    static NuParser *sharedParser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedParser = [[NuParser alloc] init];
    });
    return sharedParser;
}

+ (int) sizeOfPointer{
    return sizeof(void *);
}

+ (BOOL) loadNuFile:(NSString *) fileName fromBundleWithIdentifier:(NSString *) bundleIdentifier withContext:(NSMutableDictionary *) context{
    BOOL success = NO;
    
    @autoreleasepool {
        
        NSBundle *bundle = [NSBundle bundleWithIdentifier:bundleIdentifier];
        NSString *filePath = [bundle pathForResource:fileName ofType:@"nu"];
        if (filePath) {
            NSString *fileNu = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            if (fileNu) {
                NuParser *parser = [Nu sharedParser];
                id script = [parser parse:fileNu asIfFromFilename:[filePath cStringUsingEncoding:NSUTF8StringEncoding]];
                if (!context) context = [parser context];
                [script evalWithContext:context];
                success = YES;
            }
        }
        else {
            if ([bundleIdentifier isEqual:@"nu.programming.framework"]) {
                // try to read it if it's baked in
                
                @try
                {
                    id baked_function = [NuBridgedFunction functionWithName:[NSString stringWithFormat:@"baked_%@", fileName] signature:@"@"];
                    id baked_code = [baked_function evalWithArguments:nil context:nil];
                    if (!context) {
                        NuParser *parser = [Nu parser];
                        context = [parser context];
                    }
                    [baked_code evalWithContext:context];
                    success = YES;
                }
                @catch (id exception)
                {
                    success = NO;
                }
            }
            else {
                success = NO;
            }
        }
    }

    return success;
}

@end

#pragma mark - NuBlock.m

@interface NuBlock ()
@property (nonatomic, strong) NSMutableDictionary *context;
@property (nonatomic, strong) NuCell *body;
@property (nonatomic, strong) NuCell *parameters;
@end

@implementation NuBlock

- (void) dealloc{
    [_parameters release];
    [_body release];
    [_context release];
    [super dealloc];
}

- (id) initWithParameters:(NuCell *)p body:(NuCell *)b context:(NSMutableDictionary *)c{
    if ((self = [super init])) {
        _parameters = [p retain];
        _body = [b retain];
#ifdef CLOSE_ON_VALUES
        context = [c mutableCopy];
#else
        _context = [[NSMutableDictionary alloc] init];
        [_context setPossiblyNullObject:c forKey:PARENT_KEY];
        [_context setPossiblyNullObject:[c objectForKey:SYMBOLS_KEY] forKey:SYMBOLS_KEY];
#endif
    }
    return self;
}

- (NSString *) stringValue{
    return [NSString stringWithFormat:@"(do %@ %@)", [_parameters stringValue], [_body stringValue]];
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context{
    NSUInteger numberOfArguments = [cdr length];
    NSUInteger numberOfParameters = [_parameters length];
    
    if (numberOfArguments != numberOfParameters) {
        // is the last parameter a variable argument? if so, it's ok, and we allow it to have zero elements.
        id lastParameter = [_parameters lastObject];
        if (lastParameter && ([[lastParameter stringValue] characterAtIndex:0] == '*')) {
            if (numberOfArguments < (numberOfParameters - 1)) {
                [NSException raise:@"NuIncorrectNumberOfArguments"
                            format:@"Incorrect number of arguments to block. Received %ld but expected %ld or more: %@",
                 (unsigned long) numberOfArguments,
                 (unsigned long) (numberOfParameters - 1),
                 [_parameters stringValue]];
            }
        }
        else {
            [NSException raise:@"NuIncorrectNumberOfArguments"
                        format:@"Incorrect number of arguments to block. Received %ld but expected %ld: %@",
             (unsigned long) numberOfArguments,
             (unsigned long) numberOfParameters,
             [_parameters stringValue]];
        }
    }
    //NSLog(@"block eval %@", [cdr stringValue]);
    // loop over the parameters, looking up their values in the calling_context and copying them into the evaluation_context
    id vlist = cdr;
    id evaluation_context = [_context mutableCopy];
    
	// Insert the implicit variable "*args".  It contains the entire parameter list.
	NuSymbolTable *symbolTable = [evaluation_context objectForKey:SYMBOLS_KEY];
	[evaluation_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithString:@"*args"]];
    
    for (id pcursor in [_parameters cellEnumerator]) {
        id parameter = [pcursor car];
        if ([[parameter stringValue] characterAtIndex:0] == '*') {
            id varargs = [vlist map:^id(id cell, NSMutableDictionary *context) {
                id value = [cell car];
                if (context && context != [NSNull NU_null]) {
                    value = [value evalWithContext:context];
                }
                return value;
            } context:calling_context];
            
            [evaluation_context setPossiblyNullObject:varargs forKey:parameter];
            // this must be the last element in the parameter list
            if ([pcursor cdr] != [NSNull NU_null]) {
                [NSException raise:@"NuBadParameterList"
                            format:@"Variable argument list must be the last parameter in the parameter list: %@",
                 [_parameters stringValue]];
            }
        }
        else {
            id value = [vlist car];
            if (calling_context && (calling_context != [NSNull NU_null]))
                value = [value evalWithContext:calling_context];
            [evaluation_context setPossiblyNullObject:value forKey:parameter];
            vlist = [vlist cdr];
        }
    }
    
    // evaluate the body of the block with the saved context (implicit progn)
    id value = [NSNull NU_null];
    @try {
        value = [_body evalAsPrognInContext:evaluation_context];
    }
    @catch (NuReturnException *exception) {
        value = [exception value];
		if ([exception blockForReturn] && ([exception blockForReturn] != self)) {
			@throw(exception);
		}
    }
    @catch (id exception) {
        @throw(exception);
    }
    [value retain];
    [value autorelease];
    [evaluation_context release];
    return value;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context{
    return [self callWithArguments:cdr context:calling_context];
}

static id getObjectFromContext(id context, id symbol){
    while (IS_NOT_NULL(context)) {
        id object = [context objectForKey:symbol];
        if (object)
            return object;
        context = [context objectForKey:PARENT_KEY];
    }
    return nil;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context self:(id)object{
    NSUInteger numberOfArguments = [cdr length];
    NSUInteger numberOfParameters = [_parameters length];
    if (numberOfArguments != numberOfParameters) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
                    format:@"Incorrect number of arguments to method. Received %ld but expected %ld, %@",
         (unsigned long) numberOfArguments,
         (unsigned long) numberOfParameters,
         [_parameters stringValue]];
    }
    //    NSLog(@"block eval %@", [cdr stringValue]);
    // loop over the arguments, looking up their values in the calling_context and copying them into the evaluation_context
    id plist = _parameters;
    id vlist = cdr;
    id evaluation_context = [_context mutableCopy];
    //    NSLog(@"after copying, evaluation context %@ retain count %d", evaluation_context, [evaluation_context retainCount]);
    if (object) {
        NuSymbolTable *symbolTable = [evaluation_context objectForKey:SYMBOLS_KEY];
        // look up one level for the _class value, but allow for it to be higher (in the perverse case of nested method declarations).
        NuClass *c = getObjectFromContext([_context objectForKey:PARENT_KEY], [symbolTable symbolWithString:@"_class"]);
        [evaluation_context setPossiblyNullObject:object forKey:[symbolTable symbolWithString:@"self"]];
        [evaluation_context setPossiblyNullObject:[NuSuper superWithObject:object ofClass:[c wrappedClass]] forKey:[symbolTable symbolWithString:@"super"]];
    }
    while (plist && (plist != [NSNull NU_null]) && vlist && (vlist != [NSNull NU_null])) {
        id arg = [plist car];
        // since this message is sent by a method handler (which has already evaluated the block arguments),
        // we don't evaluate them here; instead we just copy them
        id value = [vlist car];
        //        NSLog(@"setting %@ = %@", arg, value);
        [evaluation_context setPossiblyNullObject:value forKey:arg];
        plist = [plist cdr];
        vlist = [vlist cdr];
    }
    // evaluate the body of the block with the saved context (implicit progn)
    id value = [NSNull NU_null];
    @try
    {
        value = [_body evalAsPrognInContext:evaluation_context];
    }
    @catch (NuReturnException *exception) {
        value = [exception value];
		if ([exception blockForReturn] && ([exception blockForReturn] != self)) {
			@throw(exception);
		}
    }
    @catch (id exception) {
        @throw(exception);
    }
    [value retain];
    [value autorelease];
    [evaluation_context release];
    return value;
}

@end

#pragma mark - NuBridge.m

/*
 * types:
 * c char
 * i int
 * s short
 * l long
 * q long long
 * C unsigned char
 * I unsigned int
 * S unsigned short
 * L unsigned long
 * Q unsigned long long
 * f float
 * d double
 * B bool (c++)
 * v void
 * * char *
 * @ id
 * # Class
 * : SEL
 * ? unknown
 * b4             bit field of 4 bits
 * ^type          pointer to type
 * [type]         array
 * {name=type...} structure
 * (name=type...) union
 *
 * modifiers:
 * r const
 * n in
 * N inout
 * o out
 * O bycopy
 * R byref
 * V oneway
 */

static NSMutableDictionary *nu_block_table = nil;

#ifdef __x86_64__

#define NSRECT_SIGNATURE0 "{_NSRect={_NSPoint=dd}{_NSSize=dd}}"
#define NSRECT_SIGNATURE1 "{_NSRect=\"origin\"{_NSPoint=\"x\"d\"y\"d}\"size\"{_NSSize=\"width\"d\"height\"d}}"
#define NSRECT_SIGNATURE2 "{_NSRect}"

#define CGRECT_SIGNATURE0 "{CGRect={CGPoint=dd}{CGSize=dd}}"
#define CGRECT_SIGNATURE1 "{CGRect=\"origin\"{CGPoint=\"x\"d\"y\"d}\"size\"{CGSize=\"width\"d\"height\"d}}"
#define CGRECT_SIGNATURE2 "{CGRect}"

#define NSRANGE_SIGNATURE "{_NSRange=QQ}"
#define NSRANGE_SIGNATURE1 "{_NSRange}"

#define NSPOINT_SIGNATURE0 "{_NSPoint=dd}"
#define NSPOINT_SIGNATURE1 "{_NSPoint=\"x\"d\"y\"d}"
#define NSPOINT_SIGNATURE2 "{_NSPoint}"

#define CGPOINT_SIGNATURE "{CGPoint=dd}"

#define NSSIZE_SIGNATURE0 "{_NSSize=dd}"
#define NSSIZE_SIGNATURE1 "{_NSSize=\"width\"d\"height\"d}"
#define NSSIZE_SIGNATURE2 "{_NSSize}"

#define CGSIZE_SIGNATURE "{CGSize=dd}"

#else

#define NSRECT_SIGNATURE0 "{_NSRect={_NSPoint=ff}{_NSSize=ff}}"
#define NSRECT_SIGNATURE1 "{_NSRect=\"origin\"{_NSPoint=\"x\"f\"y\"f}\"size\"{_NSSize=\"width\"f\"height\"f}}"
#define NSRECT_SIGNATURE2 "{_NSRect}"

#define CGRECT_SIGNATURE0 "{CGRect={CGPoint=ff}{CGSize=ff}}"
#define CGRECT_SIGNATURE1 "{CGRect=\"origin\"{CGPoint=\"x\"f\"y\"f}\"size\"{CGSize=\"width\"f\"height\"f}}"
#define CGRECT_SIGNATURE2 "{CGRect}"

#define NSRANGE_SIGNATURE "{_NSRange=II}"
#define NSRANGE_SIGNATURE1 "{_NSRange}"

#define NSPOINT_SIGNATURE0 "{_NSPoint=ff}"
#define NSPOINT_SIGNATURE1 "{_NSPoint=\"x\"f\"y\"f}"
#define NSPOINT_SIGNATURE2 "{_NSPoint}"

#define CGPOINT_SIGNATURE "{CGPoint=ff}"

#define NSSIZE_SIGNATURE0 "{_NSSize=ff}"
#define NSSIZE_SIGNATURE1 "{_NSSize=\"width\"f\"height\"f}"
#define NSSIZE_SIGNATURE2 "{_NSSize}"

#define CGSIZE_SIGNATURE "{CGSize=ff}"
#endif

// private ffi types
static int initialized_ffi_types = false;
static ffi_type ffi_type_nspoint;
static ffi_type ffi_type_nssize;
static ffi_type ffi_type_nsrect;
static ffi_type ffi_type_nsrange;

static void initialize_ffi_types(void){
    if (initialized_ffi_types) return;
    initialized_ffi_types = true;
    
    // It would be better to do this automatically by parsing the ObjC type signatures
    ffi_type_nspoint.size = 0;                    // to be computed automatically
    ffi_type_nspoint.alignment = 0;
    ffi_type_nspoint.type = FFI_TYPE_STRUCT;
    ffi_type_nspoint.elements = malloc(3 * sizeof(ffi_type*));
#ifdef __x86_64__
    ffi_type_nspoint.elements[0] = &ffi_type_double;
    ffi_type_nspoint.elements[1] = &ffi_type_double;
#else
    ffi_type_nspoint.elements[0] = &ffi_type_float;
    ffi_type_nspoint.elements[1] = &ffi_type_float;
#endif
    ffi_type_nspoint.elements[2] = NULL;
    
    ffi_type_nssize.size = 0;                     // to be computed automatically
    ffi_type_nssize.alignment = 0;
    ffi_type_nssize.type = FFI_TYPE_STRUCT;
    ffi_type_nssize.elements = malloc(3 * sizeof(ffi_type*));
#ifdef __x86_64__
    ffi_type_nssize.elements[0] = &ffi_type_double;
    ffi_type_nssize.elements[1] = &ffi_type_double;
#else
    ffi_type_nssize.elements[0] = &ffi_type_float;
    ffi_type_nssize.elements[1] = &ffi_type_float;
#endif
    ffi_type_nssize.elements[2] = NULL;
    
    ffi_type_nsrect.size = 0;                     // to be computed automatically
    ffi_type_nsrect.alignment = 0;
    ffi_type_nsrect.type = FFI_TYPE_STRUCT;
    ffi_type_nsrect.elements = malloc(3 * sizeof(ffi_type*));
    ffi_type_nsrect.elements[0] = &ffi_type_nspoint;
    ffi_type_nsrect.elements[1] = &ffi_type_nssize;
    ffi_type_nsrect.elements[2] = NULL;
    
    ffi_type_nsrange.size = 0;                    // to be computed automatically
    ffi_type_nsrange.alignment = 0;
    ffi_type_nsrange.type = FFI_TYPE_STRUCT;
    ffi_type_nsrange.elements = malloc(3 * sizeof(ffi_type*));
#ifdef __x86_64__
    ffi_type_nsrange.elements[0] = &ffi_type_uint64;
    ffi_type_nsrange.elements[1] = &ffi_type_uint64;
#else
    ffi_type_nsrange.elements[0] = &ffi_type_uint;
    ffi_type_nsrange.elements[1] = &ffi_type_uint;
#endif
    ffi_type_nsrange.elements[2] = NULL;
}

static char get_typeChar_from_typeString(const char *typeString){
    int i = 0;
    char typeChar = typeString[i];
    while ((typeChar == 'r') || (typeChar == 'R') ||
           (typeChar == 'n') || (typeChar == 'N') ||
           (typeChar == 'o') || (typeChar == 'O') ||
           (typeChar == 'V')
           ) {
        // uncomment the following two lines to complain about unused quantifiers in ObjC type encodings
        // if (typeChar != 'r')                      // don't worry about const
        //     NSLog(@"ignoring qualifier %c in %s", typeChar, typeString);
        typeChar = typeString[++i];
    }
    return typeChar;
}

static ffi_type *ffi_type_for_objc_type(const char *typeString){
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case 'f': return &ffi_type_float;
        case 'd': return &ffi_type_double;
        case 'v': return &ffi_type_void;
        case 'B': return &ffi_type_uchar;
        case 'C': return &ffi_type_uchar;
        case 'c': return &ffi_type_schar;
        case 'S': return &ffi_type_ushort;
        case 's': return &ffi_type_sshort;
        case 'I': return &ffi_type_uint;
        case 'i': return &ffi_type_sint;
#ifdef __x86_64__
        case 'L': return &ffi_type_ulong;
        case 'l': return &ffi_type_slong;
#else
        case 'L': return &ffi_type_uint;
        case 'l': return &ffi_type_sint;
#endif
        case 'Q': return &ffi_type_uint64;
        case 'q': return &ffi_type_sint64;
        case '@': return &ffi_type_pointer;
        case '#': return &ffi_type_pointer;
        case '*': return &ffi_type_pointer;
        case ':': return &ffi_type_pointer;
        case '^': return &ffi_type_pointer;
        case '{':
        {
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
                ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nsrect;
            }
            else if (
                     !strcmp(typeString, NSRANGE_SIGNATURE) ||
                     !strcmp(typeString, NSRANGE_SIGNATURE1)
                     ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nsrange;
            }
            else if (
                     !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                     !strcmp(typeString, CGPOINT_SIGNATURE)
                     ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nspoint;
            }
            else if (
                     !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                     !strcmp(typeString, CGSIZE_SIGNATURE)
                     ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nssize;
            }
            else {
                NSLog(@"unknown type identifier %s", typeString);
                return &ffi_type_void;
            }
        }
        default:
        {
            NSLog(@"unknown type identifier %s", typeString);
            return &ffi_type_void;                // urfkd
        }
    }
}

static size_t size_of_objc_type(const char *typeString){
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case 'f': return sizeof(float);
        case 'd': return sizeof(double);
        case 'v': return sizeof(void *);
        case 'B': return sizeof(unsigned int);
        case 'C': return sizeof(unsigned int);
        case 'c': return sizeof(int);
        case 'S': return sizeof(unsigned int);
        case 's': return sizeof(int);
        case 'I': return sizeof(unsigned int);
        case 'i': return sizeof(int);
        case 'L': return sizeof(unsigned long);
        case 'l': return sizeof(long);
        case 'Q': return sizeof(unsigned long long);
        case 'q': return sizeof(long long);
        case '@': return sizeof(void *);
        case '#': return sizeof(void *);
        case '*': return sizeof(void *);
        case ':': return sizeof(void *);
        case '^': return sizeof(void *);
        case '{':
        {
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
                ) {
                return sizeof(NSRect);
            }
            else if (
                     !strcmp(typeString, NSRANGE_SIGNATURE) ||
                     !strcmp(typeString, NSRANGE_SIGNATURE1)
                     ) {
                return sizeof(NSRange);
            }
            else if (
                     !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                     !strcmp(typeString, CGPOINT_SIGNATURE)
                     ) {
                return sizeof(NSPoint);
            }
            else if (
                     !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                     !strcmp(typeString, CGSIZE_SIGNATURE)
                     ) {
                return sizeof(NSSize);
            }
            else {
                NSLog(@"unknown type identifier %s", typeString);
                return sizeof (void *);
            }
        }
        default:
        {
            NSLog(@"unknown type identifier %s", typeString);
            return sizeof (void *);
        }
    }
}

static void *value_buffer_for_objc_type(const char *typeString){
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case 'f': return malloc(sizeof(float));
        case 'd': return malloc(sizeof(double));
        case 'v': return malloc(sizeof(void *));
        case 'B': return malloc(sizeof(unsigned int));
        case 'C': return malloc(sizeof(unsigned int));
        case 'c': return malloc(sizeof(int));
        case 'S': return malloc(sizeof(unsigned int));
        case 's': return malloc(sizeof(int));
        case 'I': return malloc(sizeof(unsigned int));
        case 'i': return malloc(sizeof(int));
        case 'L': return malloc(sizeof(unsigned long));
        case 'l': return malloc(sizeof(long));
        case 'Q': return malloc(sizeof(unsigned long long));
        case 'q': return malloc(sizeof(long long));
        case '@': return malloc(sizeof(void *));
        case '#': return malloc(sizeof(void *));
        case '*': return malloc(sizeof(void *));
        case ':': return malloc(sizeof(void *));
        case '^': return malloc(sizeof(void *));
        case '{':
        {
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
                ) {
                return malloc(sizeof(NSRect));
            }
            else if (
                     !strcmp(typeString, NSRANGE_SIGNATURE) ||
                     !strcmp(typeString, NSRANGE_SIGNATURE1)
                     ) {
                return malloc(sizeof(NSRange));
            }
            else if (
                     !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                     !strcmp(typeString, CGPOINT_SIGNATURE)
                     ) {
                return malloc(sizeof(NSPoint));
            }
            else if (
                     !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                     !strcmp(typeString, CGSIZE_SIGNATURE)
                     ) {
                return malloc(sizeof(NSSize));
            }
            else {
                NSLog(@"unknown type identifier %s", typeString);
                return malloc(sizeof (void *));
            }
        }
        default:
        {
            NSLog(@"unknown type identifier %s", typeString);
            return malloc(sizeof (void *));
        }
    }
}

static int set_objc_value_from_nu_value(void *objc_value, id nu_value, const char *typeString){
    //NSLog(@"VALUE => %s", typeString);
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case '@':
        {
            if (nu_value == [NSNull NU_null]) {
                *((id *) objc_value) = nil;
                return NO;
            }
            *((id *) objc_value) = nu_value;
            return NO;
        }
        case 'I':
#ifndef __ppc__
        case 'S':
        case 'C':
#endif
        {
            if (nu_value == [NSNull NU_null]) {
                *((unsigned int *) objc_value) = 0;
                return NO;
            }
            *((unsigned int *) objc_value) = [nu_value unsignedIntValue];
            return NO;
        }
#ifdef __ppc__
        case 'S':
        {
            if (nu_value == [NSNull NU_null]) {
                *((unsigned short *) objc_value) = 0;
                return NO;
            }
            *((unsigned short *) objc_value) = [nu_value unsignedShortValue];
            return NO;
        }
        case 'C':
        {
            if (nu_value == [NSNull NU_null]) {
                *((unsigned char *) objc_value) = 0;
                return NO;
            }
            *((unsigned char *) objc_value) = [nu_value unsignedCharValue];
            return NO;
        }
#endif
        case 'i':
#ifndef __ppc__
        case 's':
        case 'c':
#endif
        {
            if (nu_value == [NSNull null]) {
                *((int *) objc_value) = 0;
                return NO;
            }
            *((int *) objc_value) = [nu_value intValue];
            return NO;
        }
#ifdef __ppc__
        case 's':
        {
            if (nu_value == [NSNull NU_null]) {
                *((short *) objc_value) = 0;
                return NO;
            }
            *((short *) objc_value) = [nu_value shortValue];
            return NO;
        }
        case 'c':
        {
            if (nu_value == [NSNull NU_null]) {
                *((char *) objc_value) = 0;
                return NO;
            }
            *((char *) objc_value) = [nu_value charValue];
            return NO;
        }
#endif
        case 'L':
        {
            if (nu_value == [NSNull null]) {
                *((unsigned long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long *) objc_value) = [nu_value unsignedLongValue];
            return NO;
        }
        case 'l':
        {
            if (nu_value == [NSNull null]) {
                *((long *) objc_value) = 0;
                return NO;
            }
            *((long *) objc_value) = [nu_value longValue];
            return NO;
        }
        case 'Q':
        {
            if (nu_value == [NSNull null]) {
                *((unsigned long long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long long *) objc_value) = [nu_value unsignedLongLongValue];
            return NO;
        }
        case 'q':
        {
            if (nu_value == [NSNull null]) {
                *((long long *) objc_value) = 0;
                return NO;
            }
            *((long long *) objc_value) = [nu_value longLongValue];
            return NO;
        }
        case 'd':
        {
            *((double *) objc_value) = [nu_value doubleValue];
            return NO;
        }
        case 'f':
        {
            *((float *) objc_value) = (float) [nu_value doubleValue];
            return NO;
        }
        case 'v':
        {
            return NO;
        }
        case ':':
        {
            // selectors must be strings (symbols could be ok too...)
            if (!nu_value || (nu_value == [NSNull null])) {
                *((SEL *) objc_value) = 0;
                return NO;
            }
            const char *selectorName = [nu_value cStringUsingEncoding:NSUTF8StringEncoding];
            if (selectorName) {
                *((SEL *) objc_value) = sel_registerName(selectorName);
                return NO;
            }
            else {
                NSLog(@"can't convert %@ to a selector", nu_value);
                return NO;
            }
        }
        case '{':
        {
            if (
                !strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
                ) {
                NSRect *rect = (NSRect *) objc_value;
                id cursor = nu_value;
                rect->origin.x = (CGFloat) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->origin.y = (CGFloat) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->size.width = (CGFloat) [[cursor car] doubleValue];          cursor = [cursor cdr];
                rect->size.height = (CGFloat) [[cursor car] doubleValue];
                //NSLog(@"nu->rect: %x %f %f %f %f", (void *) rect, rect->origin.x, rect->origin.y, rect->size.width, rect->size.height);
                return NO;
            }
            else if (
                     !strcmp(typeString, NSRANGE_SIGNATURE) ||
                     !strcmp(typeString, NSRANGE_SIGNATURE1)
                     ) {
                NSRange *range = (NSRange *) objc_value;
                id cursor = nu_value;
                range->location = [[cursor car] intValue];          cursor = [cursor cdr];;
                range->length = [[cursor car] intValue];
                return NO;
            }
            else if (
                     !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                     !strcmp(typeString, CGSIZE_SIGNATURE)
                     ) {
                NSSize *size = (NSSize *) objc_value;
                id cursor = nu_value;
                size->width = [[cursor car] doubleValue];           cursor = [cursor cdr];;
                size->height =  [[cursor car] doubleValue];
                return NO;
            }
            else if (
                     !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                     !strcmp(typeString, CGPOINT_SIGNATURE)
                     ) {
                NSPoint *point = (NSPoint *) objc_value;
                id cursor = nu_value;
                point->x = [[cursor car] doubleValue];          cursor = [cursor cdr];;
                point->y =  [[cursor car] doubleValue];
                return NO;
            }
            else {
                NSLog(@"UNIMPLEMENTED: can't wrap structure of type %s", typeString);
                return NO;
            }
        }
            
        case '^':
        {
            if (!nu_value || (nu_value == [NSNull null])) {
                *((char ***) objc_value) = NULL;
                return NO;
            }
            // pointers require some work.. and cleanup. This LEAKS.
            if (!strcmp(typeString, "^*")) {
                // array of strings, which requires an NSArray or NSNull (handled above)
                if (nu_objectIsKindOfClass(nu_value, [NSArray class])) {
                    NSUInteger array_size = [nu_value count];
                    char **array = (char **) malloc (array_size * sizeof(char *));
                    int i;
                    for (i = 0; i < array_size; i++) {
                        array[i] = strdup([[nu_value objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding]);
                    }
                    *((char ***) objc_value) = array;
                    return NO;
                }
                else {
                    NSLog(@"can't convert value of type %s to a pointer to strings", class_getName([nu_value class]));
                    *((char ***) objc_value) = NULL;
                    return NO;
                }
            }
            else if (!strcmp(typeString, "^@")) {
                if (nu_objectIsKindOfClass(nu_value, [NuReference class])) {
                    *((id **) objc_value) = [nu_value pointerToReferencedObject];
                    return YES;
                }
            }
            else if (nu_objectIsKindOfClass(nu_value, [NuPointer class])) {
                if ([nu_value pointer] == 0)
                    [nu_value allocateSpaceForTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                *((void **) objc_value) = [nu_value pointer];
                return NO;                        // don't ask the receiver to retain this, it's just a pointer
            }
            else {
                *((void **) objc_value) = nu_value;
                return NO;                        // don't ask the receiver to retain this, it isn't expecting an object
            }
        }
            
        case '*':
        {
            *((char **) objc_value) = (char*)[[nu_value stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
            return NO;
        }
            
        case '#':
        {
            if (nu_objectIsKindOfClass(nu_value, [NuClass class])) {
                *((Class *)objc_value) = [nu_value wrappedClass];
                return NO;
            }
            else {
                NSLog(@"can't convert value of type %s to CLASS", class_getName([nu_value class]));
                *((id *) objc_value) = 0;
                return NO;
            }
        }
        default:
            NSLog(@"can't wrap argument of type %s", typeString);
    }
    return NO;
}

static id get_nu_value_from_objc_value(void *objc_value, const char *typeString){
    //NSLog(@"%s => VALUE", typeString);
    char typeChar = get_typeChar_from_typeString(typeString);
    switch(typeChar) {
        case 'v':
        {
            return [NSNull null];
        }
        case '@':
        {
            id result = *((id *)objc_value);
            return result ? result : [NSNull NU_null];
        }
        case '#':
        {
            Class c = *((Class *)objc_value);
            return c ? [[[NuClass alloc] initWithClass:c] autorelease] : [NSNull NU_null];
        }
#ifndef __ppc__
        case 'c':
        {
            return [NSNumber numberWithChar:*((char *)objc_value)];
        }
        case 's':
        {
            return [NSNumber numberWithShort:*((short *)objc_value)];
        }
#else
        case 'c':
        case 's':
#endif
        case 'i':
        {
            return [NSNumber numberWithInt:*((int *)objc_value)];
        }
#ifndef __ppc__
        case 'C':
        {
            return [NSNumber numberWithUnsignedChar:*((unsigned char *)objc_value)];
        }
        case 'S':
        {
            return [NSNumber numberWithUnsignedShort:*((unsigned short *)objc_value)];
        }
#else
        case 'C':
        case 'S':
#endif
        case 'I':
        {
            return [NSNumber numberWithUnsignedInt:*((unsigned int *)objc_value)];
        }
        case 'l':
        {
            return [NSNumber numberWithLong:*((long *)objc_value)];
        }
        case 'L':
        {
            return [NSNumber numberWithUnsignedLong:*((unsigned long *)objc_value)];
        }
        case 'q':
        {
            return [NSNumber numberWithLongLong:*((long long *)objc_value)];
        }
        case 'Q':
        {
            return [NSNumber numberWithUnsignedLongLong:*((unsigned long long *)objc_value)];
        }
        case 'f':
        {
            return [NSNumber numberWithFloat:*((float *)objc_value)];
        }
        case 'd':
        {
            return [NSNumber numberWithDouble:*((double *)objc_value)];
        }
        case ':':
        {
            SEL sel = *((SEL *)objc_value);
            return [[NSString stringWithCString:sel_getName(sel) encoding:NSUTF8StringEncoding] retain];
        }
        case '{':
        {
            if (
                !strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
                ) {
                NSRect *rect = (NSRect *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithDouble:rect->origin.x]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:rect->origin.y]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:rect->size.width]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:rect->size.height]];
                //NSLog(@"converting rect at %x to list: %@", (void *) rect, [list stringValue]);
                return list;
            }
            else if (
                     !strcmp(typeString, NSRANGE_SIGNATURE) ||
                     !strcmp(typeString, NSRANGE_SIGNATURE1)
                     ) {
                NSRange *range = (NSRange *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithInteger:range->location]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithInteger:range->length]];
                return list;
            }
            else if (
                     !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                     !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                     !strcmp(typeString, CGPOINT_SIGNATURE)
                     ) {
                NSPoint *point = (NSPoint *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithDouble:point->x]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:point->y]];
                return list;
            }
            else if (
                     !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                     !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                     !strcmp(typeString, CGSIZE_SIGNATURE)
                     ) {
                NSSize *size = (NSSize *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithDouble:size->width]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:size->height]];
                return list;
            }
            else {
                NSLog(@"UNIMPLEMENTED: can't wrap structure of type %s", typeString);
            }
        }
        case '*':
        {
            return [NSString stringWithCString:*((char **)objc_value) encoding:NSUTF8StringEncoding];
        }
        case 'B':
        {
            if (*((unsigned int *)objc_value) == 0)
                return [NSNull null];
            else
                return [NSNumber numberWithInt:1];
        }
        case '^':
        {
            if (!strcmp(typeString, "^v")) {
                if (*((unsigned long *)objc_value) == 0)
                    return [NSNull null];
                else {
                    id nupointer = [[[NuPointer alloc] init] autorelease];
                    [nupointer setPointer:*((void **)objc_value)];
                    [nupointer setTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                    return nupointer;
                }
            }
            else if (!strcmp(typeString, "^@")) {
                id reference = [[[NuReference alloc] init] autorelease];
                [reference setPointer:*((id**)objc_value)];
                return reference;
            }
            // Certain pointer types are essentially just ids.
            // CGImageRef is one. As we find others, we can add them here.
            else if (!strcmp(typeString, "^{CGImage=}")) {
                id result = *((id *)objc_value);
                return result ? result : [NSNull NU_null];
            }
            else if (!strcmp(typeString, "^{CGColor=}")) {
                id result = *((id *)objc_value);
                return result ? result : [NSNull NU_null];
            }
            else {
                if (*((unsigned long *)objc_value) == 0)
                    return [NSNull null];
                else {
                    id nupointer = [[[NuPointer alloc] init] autorelease];
                    [nupointer setPointer:*((void **)objc_value)];
                    [nupointer setTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                    return nupointer;
                }
            }
            return [NSNull null];
        }
        default:
            NSLog (@"UNIMPLEMENTED: unable to wrap object of type %s", typeString);
            return [NSNull null];
    }
    
}

static void raise_argc_exception(SEL s, NSUInteger count, NSUInteger given){
    if (given != count) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
                    format:@"Incorrect number of arguments to selector %s. Received %ld but expected %ld",
         sel_getName(s),
         (unsigned long) given,
         (unsigned long) count];
    }
}

#define BUFSIZE 500

static id nu_calling_objc_method_handler(id target, Method m, NSMutableArray *args){
    // this call seems to force the class's +initialize method to be called.
    [target class];
    
    //NSLog(@"calling ObjC method %s with target of class %@", sel_getName(method_getName(m)), [target class]);
    
    IMP imp = method_getImplementation(m);
    
    // if the imp has an associated block, this is a nu-to-nu call.
    // skip going through the ObjC runtime and evaluate the block directly.
    NuBlock *block = nil;
    if (nu_block_table &&
        ((block = [nu_block_table objectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)imp]]))) {
        //NSLog(@"nu calling nu method %s of class %@", sel_getName(method_getName(m)), [target class]);
        id arguments = [[NuCell alloc] init];
        id cursor = arguments;
        NSUInteger argc = [args count];
        int i;
        for (i = 0; i < argc; i++) {
            NuCell *nextCell = [[NuCell alloc] init];
            [cursor setCdr:nextCell];
            [nextCell release];
            cursor = [cursor cdr];
            [cursor setCar:[args objectAtIndex:i]];
        }
        id result = [block evalWithArguments:[arguments cdr] context:nil self:target];
        [arguments release];
        // ensure that methods declared to return void always return void.
        char return_type_buffer[BUFSIZE];
        method_getReturnType(m, return_type_buffer, BUFSIZE);
        return (!strcmp(return_type_buffer, "v")) ? [NSNull NU_null] : result;
    }
    
    id result;
    // if we get here, we're going through the ObjC runtime to make the call.
    @autoreleasepool {
        SEL s = method_getName(m);
        result = [NSNull null];
        
        // dynamically construct the method call
        
        
        int argument_count = method_getNumberOfArguments(m);
        
        if ( [args count] != argument_count-2) {
            
            raise_argc_exception(s, argument_count-2, [args count]);
        }
        else {
            char return_type_buffer[BUFSIZE], arg_type_buffer[BUFSIZE];
            method_getReturnType(m, return_type_buffer, BUFSIZE);
            ffi_type *result_type = ffi_type_for_objc_type(&return_type_buffer[0]);
            void *result_value = value_buffer_for_objc_type(&return_type_buffer[0]);
            ffi_type **argument_types = (ffi_type **) malloc (argument_count * sizeof(ffi_type *));
            void **argument_values = (void **) malloc (argument_count * sizeof(void *));
            int *argument_needs_retained = (int *) malloc (argument_count * sizeof(int));
            int i;
            for (i = 0; i < argument_count; i++) {
                
                method_getArgumentType(m, i, &arg_type_buffer[0], BUFSIZE);
                
                argument_types[i] = ffi_type_for_objc_type(&arg_type_buffer[0]);
                argument_values[i] = value_buffer_for_objc_type(&arg_type_buffer[0]);
                if (i == 0)
                    *((id *) argument_values[i]) = target;
                else if (i == 1)
                    *((SEL *) argument_values[i]) = method_getName(m);
                else
                    argument_needs_retained[i-2] = set_objc_value_from_nu_value(argument_values[i], [args objectAtIndex:(i-2)], &arg_type_buffer[0]);
            }
            ffi_cif cif2;
            int status = ffi_prep_cif(&cif2, FFI_DEFAULT_ABI, (unsigned int) argument_count, result_type, argument_types);
            if (status != FFI_OK) {
                NSLog (@"failed to prepare cif structure");
            }
            else {
                const char *method_name = sel_getName(method_getName(m));
                BOOL callingInitializer = !strncmp("init", method_name, 4);
                if (callingInitializer) {
                    [target retain]; // in case an init method releases its target (to return something else), we preemptively retain it
                }
                // call the method handler
                ffi_call(&cif2, FFI_FN(imp), result_value, argument_values);
                // extract the return value
                result = get_nu_value_from_objc_value(result_value, &return_type_buffer[0]);
                // NSLog(@"result is %@", result);
                // NSLog(@"retain count %d", [result retainCount]);
                
                // Return values should not require a release.
                // Either they are owned by an existing object or are autoreleased.
                // Exceptions to this rule are handled below.
                // Since these methods create new objects that aren't autoreleased, we autorelease them.
                bool already_retained =               // see Anguish/Buck/Yacktman, p. 104
                (s == @selector(alloc)) || (s == @selector(allocWithZone:))
                || (s == @selector(copy)) || (s == @selector(copyWithZone:))
                || (s == @selector(mutableCopy)) || (s == @selector(mutableCopyWithZone:))
                || (s == @selector(new));
                //NSLog(@"already retained? %d", already_retained);
                if (already_retained) {
                    [result autorelease];
                }
                
                if (callingInitializer) {
                    if (result == target) {
                        // NSLog(@"undoing preemptive retain of init target %@", [target className]);
                        [target release]; // undo our preemptive retain
                    } else {
                        // NSLog(@"keeping preemptive retain of init target %@", [target className]);
                    }
                }
                
                for (i = 0; i < [args count]; i++) {
                    if (argument_needs_retained[i])
                        [[args objectAtIndex:i] retainReferencedObject];
                }
                
                // free the value structures
                for (i = 0; i < argument_count; i++) {
                    free(argument_values[i]);
                }
                free(argument_values);
                free(result_value);
                free(argument_types);
                free(argument_needs_retained);
            }
        }
        [result retain];
    }
    
    [result autorelease];
    return result;
}

@interface NSMethodSignature (UndocumentedInterface)
+ (id) signatureWithObjCTypes:(const char*)types;
@end

static void objc_calling_nu_method_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata){
    int argc = cif->nargs - 2;
    id rcv = *((id*)args[0]);                     // this is the object getting the message
    // unused: SEL sel = *((SEL*)args[1]);
    
    // in rare cases, we need an autorelease pool (specifically detachNewThreadSelector:toTarget:withObject:)
    // previously we used a private api to verify that one existed before creating a new one. Now we just make one.
    char *resultType = NULL;
    @autoreleasepool {
        NuBlock *block = ((NuBlock **)userdata)[1];
        //NSLog(@"----------------------------------------");
        //NSLog(@"calling block %@", [block stringValue]);
        id arguments = [[NuCell alloc] init];
        id cursor = arguments;
        int i;
        for (i = 0; i < argc; i++) {
            NuCell *nextCell = [[NuCell alloc] init];
            [cursor setCdr:nextCell];
            [nextCell release];
            cursor = [cursor cdr];
            id value = get_nu_value_from_objc_value(args[i+2], ((char **)userdata)[i+2]);
            [cursor setCar:value];
        }
        id result = [block evalWithArguments:[arguments cdr] context:nil self:rcv];
        //NSLog(@"in nu method handler, putting result %@ in %x with type %s", [result stringValue], (int) returnvalue, ((char **)userdata)[0]);
        resultType = (((char **)userdata)[0])+1;// skip the first character, it's a flag
        set_objc_value_from_nu_value(returnvalue, result, resultType);
#ifdef __ppc__
        // It appears that at least on PowerPC architectures, small values (short, char, ushort, uchar) passed in via
        // the ObjC runtime use their actual type while function return values are coerced up to integers.
        // I suppose this is because values are passed as arguments in memory and returned in registers.
        // This may also be the case on x86 but is unobserved because x86 is little endian.
        switch (resultType[0]) {
            case 'C':
            {
                *((unsigned int *) returnvalue) = *((unsigned char *) returnvalue);
                break;
            }
            case 'c':
            {
                *((int *) returnvalue) = *((char *) returnvalue);
                break;
            }
            case 'S':
            {
                *((unsigned int *) returnvalue) = *((unsigned short *) returnvalue);
                break;
            }
            case 's':
            {
                *((int *) returnvalue) = *((short *) returnvalue);
                break;
            }
        }
#endif
        
        if (((char **)userdata)[0][0] == '!') {
            //NSLog(@"retaining result for object %@, count = %d", *(id *)returnvalue, [*(id *)returnvalue retainCount]);
            [*((id *)returnvalue) retain];
        }
        [arguments release];
        
        if (resultType[0] == '@')
            [*((id *)returnvalue) retain];
    }

    if (resultType[0] == '@')
        [*((id *)returnvalue) autorelease];
}

static char **generate_userdata(SEL sel, NuBlock *block, const char *signature){
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    const char *return_type_string = [methodSignature methodReturnType];
    NSUInteger argument_count = [methodSignature numberOfArguments];
    char **userdata = (char **) malloc ((argument_count+3) * sizeof(char*));
    userdata[0] = (char *) malloc (2 + strlen(return_type_string));
    const char *methodName = sel_getName(sel);
    BOOL returnsRetainedResult = NO;
    if ((!strcmp(methodName, "alloc")) ||
        (!strcmp(methodName, "allocWithZone:")) ||
        (!strcmp(methodName, "copy")) ||
        (!strcmp(methodName, "copyWithZone:")) ||
        (!strcmp(methodName, "mutableCopy")) ||
        (!strcmp(methodName, "mutableCopyWithZone:")) ||
        (!strcmp(methodName, "new")))
        returnsRetainedResult = YES;
    if (returnsRetainedResult)
        sprintf(userdata[0], "!%s", return_type_string);
    else
        sprintf(userdata[0], " %s", return_type_string);
    //NSLog(@"constructing handler for method %s with %d arguments and returnType %s", methodName, argument_count, userdata[0]);
    userdata[1] = (char *) block;
    [block retain];
    int i;
    for (i = 0; i < argument_count; i++) {
        const char *argument_type_string = [methodSignature getArgumentTypeAtIndex:i];
        if (i > 1) userdata[i] = strdup(argument_type_string);
    }
    userdata[argument_count] = NULL;
    return userdata;
}

static IMP construct_method_handler(SEL sel, NuBlock *block, const char *signature){
    char **userdata = generate_userdata(sel, block, signature);
    IMP imp = [NuHandlerWarehouse handlerWithSelector:sel block:block signature:signature userdata:userdata];
    if (imp) {
        return imp;
    }
    int argument_count = 0;
    while (userdata[argument_count] != 0) argument_count++;
#if 0
    const char *methodName = sel_getName(sel);
    NSLog(@"using libffi to construct handler for method %s with %d arguments and signature %s", methodName, argument_count, signature);
#endif
    ffi_type **argument_types = (ffi_type **) malloc ((argument_count+1) * sizeof(ffi_type *));
    ffi_type *result_type = ffi_type_for_objc_type(userdata[0]+1);
    argument_types[0] = ffi_type_for_objc_type("@");
    argument_types[1] = ffi_type_for_objc_type(":");
    for (int i = 2; i < argument_count; i++)
        argument_types[i] = ffi_type_for_objc_type(userdata[i]);
    argument_types[argument_count] = NULL;
    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
    if (cif == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for cif structure)", signature);
        return NULL;
    }
    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_cif failed)", signature);
        return NULL;
    }
    ffi_closure *closure = (ffi_closure *)mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if (closure == (ffi_closure *) -1) {
        NSLog(@"unable to prepare closure for signature %s (mmap failed with error %d)", signature, errno);
        return NULL;
    }
    if (closure == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for closure)", signature);
        return NULL;
    }
    if (ffi_prep_closure(closure, cif, objc_calling_nu_method_handler, userdata) != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_closure failed)", signature);
        return NULL;
    }
    if (mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1) {
        NSLog(@"unable to prepare closure for signature %s (mprotect failed with error %d)", signature, errno);
        return NULL;
    }
    return (IMP) closure;
}

static id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block){
    const char *method_name_str = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    const char *signature_str = [signature cStringUsingEncoding:NSUTF8StringEncoding];
    SEL selector = sel_registerName(method_name_str);
    
    //NuSymbolTable *symbolTable = [[block context] objectForKey:SYMBOLS_KEY];
    //[[block context] setPossiblyNullObject:[[NuClass alloc] initWithClass:c] forKey:[symbolTable symbolWithString:@"_class"]];
    
    IMP imp = construct_method_handler(selector, block, signature_str);
    if (imp == NULL) {
        NSLog(@"failed to construct handler for %s(%s)", method_name_str, signature_str);
        return [NSNull null];
    }
    
    // save the block in a hash table keyed by the imp.
    // this will let us introspect methods and optimize nu-to-nu method calls
    if (!nu_block_table) nu_block_table = [[NSMutableDictionary alloc] init];
    // watch for problems caused by these ugly casts...
    [nu_block_table setObject:block forKey:[NSNumber numberWithUnsignedLong:(unsigned long) imp]];

    // insert the method handler in the class method table
    nu_class_replaceMethod(c, selector, imp, signature_str);
    //NSLog(@"setting handler for %s(%s) in class %s", method_name_str, signature_str, class_getName(c));
    return [NSNull null];
}

@interface NuBridgedFunction (){
    char *_name;
    char *_signature;
    void *_function;
}
@end

@implementation NuBridgedFunction

- (void) dealloc{
    free(_name);
    free(_signature);
    [super dealloc];
}

- (NuBridgedFunction *) initWithName:(NSString *)n signature:(NSString *)s{
    _name = strdup([n cStringUsingEncoding:NSUTF8StringEncoding]);
    _signature = strdup([s cStringUsingEncoding:NSUTF8StringEncoding]);
    _function = dlsym(RTLD_DEFAULT, _name);
    if (!_function) {
        [NSException raise:@"NuCantFindBridgedFunction"
                    format:@"%s\n%s\n%s\n", dlerror(),
         "If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.",
         "In Xcode, check the 'Preserve Private External Symbols' checkbox."];
    }
    return self;
}

+ (NuBridgedFunction *) functionWithName:(NSString *)name signature:(NSString *)signature{
    const char *function_name = [name cStringUsingEncoding:NSUTF8StringEncoding];
    void *function = dlsym(RTLD_DEFAULT, function_name);
    if (!function) {
        [NSException raise:@"NuCantFindBridgedFunction"
                    format:@"%s\n%s\n%s\n", dlerror(),
         "If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.",
         "In Xcode, check the 'Preserve Private External Symbols' checkbox."];
    }
    NuBridgedFunction *wrapper = [[[NuBridgedFunction alloc] initWithName:name signature:signature] autorelease];
    return wrapper;
}

- (id) evalWithArguments:(id) cdr context:(NSMutableDictionary *) context{
    //NSLog(@"----------------------------------------");
    //NSLog(@"calling C function %s with signature %s", name, signature);
    id result;
    
    @autoreleasepool {
        char *return_type_identifier = strdup(_signature);
        nu_markEndOfObjCTypeString(return_type_identifier, strlen(return_type_identifier));
        
        int argument_count = 0;
        char *argument_type_identifiers[100];
        char *cursor = &_signature[strlen(return_type_identifier)];
        while (*cursor != 0) {
            argument_type_identifiers[argument_count] = strdup(cursor);
            nu_markEndOfObjCTypeString(argument_type_identifiers[argument_count], strlen(cursor));
            cursor = &cursor[strlen(argument_type_identifiers[argument_count])];
            argument_count++;
        }
        //NSLog(@"calling return type is %s", return_type_identifier);
        int i;
        for (i = 0; i < argument_count; i++) {
            //    NSLog(@"argument %d type is %s", i, argument_type_identifiers[i]);
        }
        
        ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
        
        ffi_type *result_type = ffi_type_for_objc_type(return_type_identifier);
        ffi_type **argument_types = (argument_count == 0) ? NULL : (ffi_type **) malloc (argument_count * sizeof(ffi_type *));
        for (i = 0; i < argument_count; i++)
            argument_types[i] = ffi_type_for_objc_type(argument_type_identifiers[i]);
        
        int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
        if (status != FFI_OK) {
            NSLog (@"failed to prepare cif structure");
            return [NSNull null];
        }
        
        id arg_cursor = cdr;
        void *result_value = value_buffer_for_objc_type(return_type_identifier);
        void **argument_values = (void **) (argument_count ? malloc (argument_count * sizeof(void *)) : NULL);
        
        for (i = 0; i < argument_count; i++) {
            argument_values[i] = value_buffer_for_objc_type( argument_type_identifiers[i]);
            id arg_value = [[arg_cursor car] evalWithContext:context];
            set_objc_value_from_nu_value(argument_values[i], arg_value, argument_type_identifiers[i]);
            arg_cursor = [arg_cursor cdr];
        }
        ffi_call(cif, FFI_FN(_function), result_value, argument_values);
        result = get_nu_value_from_objc_value(result_value, return_type_identifier);
        
        // free the value structures
        for (i = 0; i < argument_count; i++) {
            free(argument_values[i]);
            free(argument_type_identifiers[i]);
        }
        free(argument_values);
        free(result_value);
        free(return_type_identifier);
        free(argument_types);
        free(cif);
        
        [result retain];
    }
    [result autorelease];
    return result;
}

@end

@implementation NuBridgedConstant

+ (id) constantWithName:(NSString *) name signature:(NSString *) signature{
    const char *constant_name = [name cStringUsingEncoding:NSUTF8StringEncoding];
    void *constant = dlsym(RTLD_DEFAULT, constant_name);
    if (!constant) {
        NSLog(@"%s", dlerror());
        NSLog(@"If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.");
        NSLog(@"In Xcode, check the 'Preserve Private External Symbols' checkbox.");
        return nil;
    }
    return get_nu_value_from_objc_value(constant, [signature cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end


static NuSymbol *oneway_symbol, *in_symbol, *out_symbol, *inout_symbol, *bycopy_symbol, *byref_symbol, *const_symbol,
*void_symbol, *star_symbol, *id_symbol, *voidstar_symbol, *idstar_symbol, *int_symbol, *long_symbol, *NSComparisonResult_symbol,
*BOOL_symbol, *double_symbol, *float_symbol, *NSRect_symbol, *NSPoint_symbol, *NSSize_symbol, *NSRange_symbol,
*CGRect_symbol, *CGPoint_symbol, *CGSize_symbol,
*SEL_symbol, *Class_symbol;


static void prepare_symbols(NuSymbolTable *symbolTable){
    oneway_symbol = [symbolTable symbolWithString:@"oneway"];
    in_symbol = [symbolTable symbolWithString:@"in"];
    out_symbol = [symbolTable symbolWithString:@"out"];
    inout_symbol = [symbolTable symbolWithString:@"inout"];
    bycopy_symbol = [symbolTable symbolWithString:@"bycopy"];
    byref_symbol = [symbolTable symbolWithString:@"byref"];
    const_symbol = [symbolTable symbolWithString:@"const"];
    void_symbol = [symbolTable symbolWithString:@"void"];
    star_symbol = [symbolTable symbolWithString:@"*"];
    id_symbol = [symbolTable symbolWithString:@"id"];
    voidstar_symbol = [symbolTable symbolWithString:@"void*"];
    idstar_symbol = [symbolTable symbolWithString:@"id*"];
    int_symbol = [symbolTable symbolWithString:@"int"];
    long_symbol = [symbolTable symbolWithString:@"long"];
    NSComparisonResult_symbol = [symbolTable symbolWithString:@"NSComparisonResult"];
    BOOL_symbol = [symbolTable symbolWithString:@"BOOL"];
    double_symbol = [symbolTable symbolWithString:@"double"];
    float_symbol = [symbolTable symbolWithString:@"float"];
    NSRect_symbol = [symbolTable symbolWithString:@"NSRect"];
    NSPoint_symbol = [symbolTable symbolWithString:@"NSPoint"];
    NSSize_symbol = [symbolTable symbolWithString:@"NSSize"];
    NSRange_symbol = [symbolTable symbolWithString:@"NSRange"];
    CGRect_symbol = [symbolTable symbolWithString:@"CGRect"];
    CGPoint_symbol = [symbolTable symbolWithString:@"CGPoint"];
    CGSize_symbol = [symbolTable symbolWithString:@"CGSize"];
    SEL_symbol = [symbolTable symbolWithString:@"SEL"];
    Class_symbol = [symbolTable symbolWithString:@"Class"];
}

static NSString *signature_for_identifier(NuCell *cell, NuSymbolTable *symbolTable){
    static NuSymbolTable *currentSymbolTable = nil;
    if (currentSymbolTable != symbolTable) {
        prepare_symbols(symbolTable);
        currentSymbolTable = symbolTable;
    }
    NSMutableArray *modifiers = nil;
    NSMutableString *signature = [NSMutableString string];
    id cursor = cell;
    BOOL finished = NO;
    while (cursor && cursor != [NSNull NU_null]) {
        if (finished) {
            // ERROR!
            NSLog(@"I can't bridge this return type yet: %@ (%@)", [cell stringValue], signature);
            return @"?";
        }
        id cursor_car = [cursor car];
        if (cursor_car == oneway_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"V"];
        }
        else if (cursor_car == in_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"n"];
        }
        else if (cursor_car == out_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"o"];
        }
        else if (cursor_car == inout_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"N"];
        }
        else if (cursor_car == bycopy_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"O"];
        }
        else if (cursor_car == byref_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"R"];
        }
        else if (cursor_car == const_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"r"];
        }
        else if (cursor_car == void_symbol) {
            if (![cursor cdr] || ([cursor cdr] == [NSNull null])) {
                if (modifiers)
                    [signature appendString:[[modifiers sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@""]];
                [signature appendString:@"v"];
                finished = YES;
            }
            else if ([[cursor cdr] car] == star_symbol) {
                [signature appendString:@"^v"];
                cursor = [cursor cdr];
                finished = YES;
            }
        }
        else if (cursor_car == id_symbol) {
            if (![cursor cdr] || ([cursor cdr] == [NSNull null])) {
                if (modifiers)
                    [signature appendString:[[modifiers sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@""]];
                [signature appendString:@"@"];
                finished = YES;
            }
            else if ([[cursor cdr] car] == star_symbol) {
                [signature appendString:@"^@"];
                cursor = [cursor cdr];
                finished = YES;
            }
        }
        else if (cursor_car == voidstar_symbol) {
            [signature appendString:@"^v"];
            finished = YES;
        }
        else if (cursor_car == idstar_symbol) {
            [signature appendString:@"^@"];
            finished = YES;
        }
        else if (cursor_car == int_symbol) {
            [signature appendString:@"i"];
            finished = YES;
        }
        else if (cursor_car == long_symbol) {
            [signature appendString:@"l"];
            finished = YES;
        }
        else if (cursor_car == NSComparisonResult_symbol) {
            if (sizeof(NSComparisonResult) == 4)
                [signature appendString:@"i"];
            else
                [signature appendString:@"q"];
            finished = YES;
        }
        else if (cursor_car == BOOL_symbol) {
            [signature appendString:@"C"];
            finished = YES;
        }
        else if (cursor_car == double_symbol) {
            [signature appendString:@"d"];
            finished = YES;
        }
        else if (cursor_car == float_symbol) {
            [signature appendString:@"f"];
            finished = YES;
        }
        else if (cursor_car == NSRect_symbol) {
            [signature appendString:@NSRECT_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == NSPoint_symbol) {
            [signature appendString:@NSPOINT_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == NSSize_symbol) {
            [signature appendString:@NSSIZE_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == NSRange_symbol) {
            [signature appendString:@NSRANGE_SIGNATURE];
            finished = YES;
        }
        else if (cursor_car == CGRect_symbol) {
            [signature appendString:@CGRECT_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == CGPoint_symbol) {
            [signature appendString:@CGPOINT_SIGNATURE];
            finished = YES;
        }
        else if (cursor_car == CGSize_symbol) {
            [signature appendString:@CGSIZE_SIGNATURE];
            finished = YES;
        }
        else if (cursor_car == SEL_symbol) {
            [signature appendString:@":"];
            finished = YES;
        }
        else if (cursor_car == Class_symbol) {
            [signature appendString:@"#"];
            finished = YES;
        }
        cursor = [cursor cdr];
    }
    if (finished)
        return signature;
    else {
        NSLog(@"I can't bridge this return type yet: %@ (%@)", [cell stringValue], signature);
        return @"?";
    }
}

static id help_add_method_to_class(Class classToExtend, id cdr, NSMutableDictionary *context, BOOL addClassMethod){
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    
    id returnType = [NSNull null];
    id selector = [[[NuCell alloc] init] autorelease];
    id argumentTypes = [NSNull null];
    id argumentNames = [NSNull null];
    id isSymbol = [symbolTable symbolWithString:@"is"];
    id cursor = cdr;
    id selector_cursor = nil;
    id argumentTypes_cursor = nil;
    id argumentNames_cursor = nil;
    
    if (cursor && (cursor != [NSNull null]) && ([cursor car] != isSymbol)) {
        // scan the return type
        if (![[cursor car] atom]) {
            returnType = [cursor car] ;
            cursor = [cursor cdr];
        }
        else {
            // The return type specifier must be a list (in parens).  If it is missing, leave it as null.
            returnType = [NSNull NU_null];
        }
        if (cursor && (cursor != [NSNull null])) {
            [selector setCar:[cursor car]];       // scan a part of the selector
            cursor = [cursor cdr];
            if (cursor && (cursor != [NSNull null])) {
                if ([cursor car] != isSymbol) {
                    argumentTypes = [[[NuCell alloc] init] autorelease];
                    argumentNames = [[[NuCell alloc] init] autorelease];
                    if (![[cursor car] atom]) {
                        // the argument type specifier must be a list. If it is missing, we'll use a default.
                        [argumentTypes setCar:[cursor car]];
                        cursor = [cursor cdr];
                    }
                    if (cursor && (cursor != [NSNull null])) {
                        [argumentNames setCar:[cursor car]];
                        cursor = [cursor cdr];
                        if (cursor && (cursor != [NSNull null])) {
                            selector_cursor = selector;
                            argumentTypes_cursor = argumentTypes;
                            argumentNames_cursor = argumentNames;
                        }
                    }
                }
            }
        }
    }
    // scan each remaining part of the selector
    while (cursor && (cursor != [NSNull null]) && ([cursor car] != isSymbol)) {
        [selector_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        [argumentTypes_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        [argumentNames_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        selector_cursor = [selector_cursor cdr];
        argumentTypes_cursor = [argumentTypes_cursor cdr];
        argumentNames_cursor = [argumentNames_cursor cdr];
        
        [selector_cursor setCar:[cursor car]];
        cursor = [cursor cdr];
        if (cursor && (cursor != [NSNull null])) {
            if (![[cursor car] atom]) {
                // the argument type specifier must be a list.  If it is missing, we'll use a default.
                [argumentTypes_cursor setCar:[cursor car]];
                cursor = [cursor cdr];
            }
            if (cursor && (cursor != [NSNull null])) {
                [argumentNames_cursor setCar:[cursor car]];
                cursor = [cursor cdr];
            }
        }
    }
    
    if (cursor && (cursor != [NSNull null])) {
        //NSLog(@"selector: %@", [selector stringValue]);
        //NSLog(@"argument names: %@", [argumentNames stringValue]);
        //NSLog(@"argument types:%@", [argumentTypes stringValue]);
        //NSLog(@"returns: %@", [returnType stringValue]);
        
        // skip the is
        cursor = [cursor cdr];
        
        // combine the selectors into the method name
        NSMutableString *methodName = [[[NSMutableString alloc] init] autorelease];
        selector_cursor = selector;
        while (selector_cursor && (selector_cursor != [NSNull null])) {
            [methodName appendString:[[selector_cursor car] stringValue]];
            selector_cursor = [selector_cursor cdr];
        }
        
        NSMutableString *signature = nil;
        
        if ((returnType == [NSNull NU_null]) || ([argumentTypes length] < [argumentNames length])) {
            // look up the signature
            SEL selector = sel_registerName([methodName cStringUsingEncoding:NSUTF8StringEncoding]);
            NSMethodSignature *methodSignature = [classToExtend instanceMethodSignatureForSelector:selector];
            
            if (!methodSignature)
                methodSignature = [classToExtend methodSignatureForSelector:selector];
            if (methodSignature)
                signature = [NSMutableString stringWithString:[methodSignature typeString]];
            // if we can't find a signature, use a default
            if (!signature) {
                // NSLog(@"no signature found.  treating all arguments and the return type as (id)");
                signature = [NSMutableString stringWithString:@"@@:"];
                int i;
                for (i = 0; i < [argumentNames length]; i++) {
                    [signature appendString:@"@"];
                }
            }
        }
        else {
            // build the signature, first get the return type
            signature = [NSMutableString string];
            [signature appendString:signature_for_identifier(returnType, symbolTable)];
            
            // then add the common stuff
            [signature appendString:@"@:"];
            
            // then describe the arguments
            argumentTypes_cursor = argumentTypes;
            while (argumentTypes_cursor && (argumentTypes_cursor != [NSNull null])) {
                id typeIdentifier = [argumentTypes_cursor car];
                [signature appendString:signature_for_identifier(typeIdentifier, symbolTable)];
                argumentTypes_cursor = [argumentTypes_cursor cdr];
            }
        }
        id body = cursor;
        NuBlock *block = [[[NuBlock alloc] initWithParameters:argumentNames body:body context:context] autorelease];
        [[block context]
         setPossiblyNullObject:methodName
         forKey:[symbolTable symbolWithString:@"_method"]];
        return add_method_to_class(
                                   addClassMethod ? object_getClass(classToExtend) : classToExtend,
                                   methodName, signature, block);
    }
    else {
        // not good. you probably forgot the "is" in your method declaration.
        [NSException raise:@"NuBadMethodDeclaration"
                    format:@"invalid method declaration: %@",
         [cdr stringValue]];
        return nil;
    }
}

#ifdef __BLOCKS__

static id make_cblock (NuBlock *nuBlock, NSString *signature);
static void objc_calling_nu_block_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata);
static char **generate_block_userdata(NuBlock *nuBlock, const char *signature);
static void *construct_block_handler(NuBlock *block, const char *signature);

@interface NuBridgedBlock (){
	NuBlock *_nuBlock;
	id _cBlock;
}
@end

@implementation NuBridgedBlock

+(id)cBlockWithNuBlock:(NuBlock*)nb signature:(NSString*)sig{
	return [[[[self alloc] initWithNuBlock:nb signature:sig] autorelease] cBlock];
}

-(id)initWithNuBlock:(NuBlock*)nb signature:(NSString*)sig{
	_nuBlock = [nb retain];
	_cBlock = make_cblock(nb,sig);
	
	return self;
}

-(NuBlock*)nuBlock{return [[_nuBlock retain] autorelease];}

-(id)cBlock{return [[_cBlock retain] autorelease];}

-(void)dealloc{
	[_nuBlock release];
	[_cBlock release];
	[super dealloc];
}

@end

//the caller gets ownership of the block
static id make_cblock (NuBlock *nuBlock, NSString *signature){
	void *funcptr = construct_block_handler(nuBlock, [signature UTF8String]);
    
	int i = 0xFFFF;
	void(^cBlock)(void)=[^(void){printf("%i",i);} copy];
	
#ifdef __x86_64__
	/*  this is what happens when a block is called on x86 64
	 mov    %rax,-0x18(%rbp)		//the pointer to the block object is in rax
	 mov    -0x18(%rbp),%rax
	 mov    0x10(%rax),%rax			//the pointer to the block function is at +0x10 into the block object
	 mov    -0x18(%rbp),%rdi		//the first argument (this examples has no others) is always the pointer to the block object
	 callq  *%rax
     */
	//2*(sizeof(void*)) = 0x10
	*((void **)(id)cBlock + 2) = (void *)funcptr;
#else
	/*  this is what happens when a block is called on x86 32
	 mov    %eax,-0x14(%ebp)		//the pointer to the block object is in eax
	 mov    -0x14(%ebp),%eax
	 mov    0xc(%eax),%eax			//the pointer to the block function is at +0xc into the block object
	 mov    %eax,%edx
	 mov    -0x14(%ebp),%eax		//the first argument (this examples has no others) is always the pointer to the block object
	 mov    %eax,(%esp)
	 call   *%edx
	 */
	//3*(sizeof(void*)) = 0xc
	*((void **)(id)cBlock + 3) = (void *)funcptr;
#endif
	return cBlock;
}

static void objc_calling_nu_block_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata){
    int argc = cif->nargs - 1;
	//void *ptr = (void*)args[0]  //don't need this first parameter
    // see objc_calling_nu_method_handler
    
    char *resultType = NULL;
    @autoreleasepool {
        NuBlock *block = ((NuBlock **)userdata)[1];
        //NSLog(@"----------------------------------------");
        //NSLog(@"calling block %@", [block stringValue]);
        id arguments = [[NuCell alloc] init];
        id cursor = arguments;
        int i;
        for (i = 0; i < argc; i++) {
            NuCell *nextCell = [[NuCell alloc] init];
            [cursor setCdr:nextCell];
            [nextCell release];
            cursor = [cursor cdr];
            id value = get_nu_value_from_objc_value(args[i+1], ((char **)userdata)[i+2]);
            [cursor setCar:value];
        }
        //NSLog(@"in nu method handler, using arguments %@", [arguments stringValue]);
        id result = [block evalWithArguments:[arguments cdr] context:nil];
        //NSLog(@"in nu method handler, putting result %@ in %x with type %s", [result stringValue], (size_t) returnvalue, ((char **)userdata)[0]);
        resultType = (((char **)userdata)[0])+1;// skip the first character, it's a flag
        set_objc_value_from_nu_value(returnvalue, result, resultType);
        [arguments release];
        
        if (resultType[0] == '@')
            [*((id *)returnvalue) retain];
    }
    

    if (resultType[0] == '@')
        [*((id *)returnvalue) autorelease];
}

static char **generate_block_userdata(NuBlock *nuBlock, const char *signature){
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    const char *return_type_string = [methodSignature methodReturnType];
    NSUInteger argument_count = [methodSignature numberOfArguments];
    char **userdata = (char **) malloc ((argument_count+3) * sizeof(char*));
    userdata[0] = (char *) malloc (2 + strlen(return_type_string));
    
	//assume blocks never return retained results
	sprintf(userdata[0], " %s", return_type_string);
    
	//so first element is return type, second is nuBlock
    userdata[1] = (char *) nuBlock;
    [nuBlock retain];
    int i;
    for (i = 0; i < argument_count; i++) {
        const char *argument_type_string = [methodSignature getArgumentTypeAtIndex:i];
        userdata[i+2] = strdup(argument_type_string);
    }
    userdata[argument_count+2] = NULL;
	
#if 0
	NSLog(@"Userdata for block: %@, signature: %s", [nuBlock stringValue], signature);
	for (int i = 0; i < argument_count+2; i++)
	{	if (i != 1)
        NSLog(@"userdata[%i] = %s",i,userdata[i]);	}
#endif
    return userdata;
}


static void *construct_block_handler(NuBlock *block, const char *signature){
    char **userdata = generate_block_userdata(block, signature);
    
    int argument_count = 0;
    while (userdata[argument_count] != 0) argument_count++;
	argument_count-=1; //unlike a method call, c blocks have one, not two hidden args (see comments in make_cblock()
#if 0
	NSLog(@"using libffi to construct handler for nu block with %d arguments and signature %s", argument_count, signature);
#endif
	if (argument_count < 0) {
        NSLog(@"error in argument construction");
        return NULL;
    }
    
    ffi_type **argument_types = (ffi_type **) malloc ((argument_count+1) * sizeof(ffi_type *));
    ffi_type *result_type = ffi_type_for_objc_type(userdata[0]+1);
    
    argument_types[0] = ffi_type_for_objc_type("^?");
	
    for (int i = 1; i < argument_count; i++)
        argument_types[i] = ffi_type_for_objc_type(userdata[i+1]);
    argument_types[argument_count] = NULL;
    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
    if (cif == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for cif structure)", signature);
        return NULL;
    }
    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_cif failed)", signature);
        return NULL;
    }
    ffi_closure *closure = (ffi_closure *)mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if (closure == (ffi_closure *) -1) {
        NSLog(@"unable to prepare closure for signature %s (mmap failed with error %d)", signature, errno);
        return NULL;
    }
    if (closure == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for closure)", signature);
        return NULL;
    }
    if (ffi_prep_closure(closure, cif, objc_calling_nu_block_handler, userdata) != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_closure failed)", signature);
        return NULL;
    }
    if (mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1) {
        NSLog(@"unable to prepare closure for signature %s (mprotect failed with error %d)", signature, errno);
        return NULL;
    }
    return (void*)closure;
}

#endif //__BLOCKS__

#pragma mark - NuBridgeSupport.m

#if !TARGET_OS_IPHONE

static NSString *getTypeStringFromNode(id node){
	static BOOL use64BitTypes = (sizeof(void *) == 8);
    if (use64BitTypes ) {
        id type64Attribute = [node attributeForName:@"type64"];
        if (type64Attribute)
            return [type64Attribute stringValue];
    }
    return [[node attributeForName:@"type"] stringValue];
}

@implementation NuBridgeSupport

+ (void)importLibrary:(NSString *) libraryPath{
    //NSLog(@"importing library %@", libraryPath);
    dlopen([libraryPath cStringUsingEncoding:NSUTF8StringEncoding], RTLD_LAZY | RTLD_GLOBAL);
}

+ (void)importFramework:(NSString *) framework fromPath:(NSString *) path intoDictionary:(NSMutableDictionary *) BridgeSupport{
    NSMutableDictionary *frameworks = [BridgeSupport valueForKey:@"frameworks"];
    if ([frameworks valueForKey:framework])
        return;
    else
        [frameworks setValue:framework forKey:framework];
    
    NSString *xmlPath;                            // constants, enums, functions, and more are described in an XML file.
    NSString *dylibPath;                          // sometimes a dynamic library is included to provide implementations of inline functions.
    
    if (path) {
        xmlPath = [NSString stringWithFormat:@"%@/Resources/BridgeSupport/%@.bridgesupport", path, framework];
        dylibPath = [NSString stringWithFormat:@"%@/Resources/BridgeSupport/%@.dylib", path, framework];
    }
    else {
        xmlPath = [NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework/Resources/BridgeSupport/%@.bridgesupport", framework, framework];
        dylibPath = [NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework/Resources/BridgeSupport/%@.dylib", framework, framework];
    }
    
    if ([NSFileManager fileExistsNamed:dylibPath])
        [self importLibrary:dylibPath];
    
    NSMutableDictionary *constants = [BridgeSupport valueForKey:@"constants"];
    NSMutableDictionary *enums =     [BridgeSupport valueForKey:@"enums"];
    NSMutableDictionary *functions = [BridgeSupport valueForKey:@"functions"];
    
    NSXMLDocument *xmlDocument = [[[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:xmlPath] options:0 error:nil] autorelease];
    if (xmlDocument) {
        id node;
        NSEnumerator *childEnumerator = [[[xmlDocument rootElement] children] objectEnumerator];
        while ((node = [childEnumerator nextObject])) {
            if ([[node name] isEqual:@"depends_on"]) {
                id fileName = [[node attributeForName:@"path"] stringValue];
                id frameworkName = [[[fileName lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0];
                [NuBridgeSupport importFramework:frameworkName fromPath:fileName intoDictionary:BridgeSupport];
            }
            else if ([[node name] isEqual:@"constant"]) {
                [constants setValue:getTypeStringFromNode(node)
                             forKey:[[node attributeForName:@"name"] stringValue]];
            }
            else if ([[node name] isEqual:@"enum"]) {
                [enums setValue:[NSNumber numberWithInt:[[[node attributeForName:@"value"] stringValue] intValue]]
                         forKey:[[node attributeForName:@"name"] stringValue]];
            }
            else if ([[node name] isEqual:@"function"]) {
                id name = [[node attributeForName:@"name"] stringValue];
                id argumentTypes = [NSMutableString string];
                id returnType = @"v";
                id child;
                NSEnumerator *nodeChildEnumerator = [[node children] objectEnumerator];
                while ((child = [nodeChildEnumerator nextObject])) {
                    if ([[child name] isEqual:@"arg"]) {
                        id typeModifier = [child attributeForName:@"type_modifier"];
                        if (typeModifier) {
                            [argumentTypes appendString:[typeModifier stringValue]];
                        }
						[argumentTypes appendString:getTypeStringFromNode(child)];
                    }
                    else if ([[child name] isEqual:@"retval"]) {
						returnType = getTypeStringFromNode(child);
                    }
                    else {
                        NSLog(@"unrecognized type #{[child XMLString]}");
                    }
                }
                id signature = [NSString stringWithFormat:@"%@%@", returnType, argumentTypes];
                [functions setValue:signature forKey:name];
            }
        }
    }
    else {
        // don't complain about missing bridge support files...
        //NSString *reason = [NSString stringWithFormat:@"unable to find BridgeSupport file for %@", framework];
        //[[NSException exceptionWithName:@"NuBridgeSupportMissing" reason:reason userInfo:nil] raise];
    }
}

+ (void) prune{
    NuSymbolTable *symbolTable = [NuSymbolTable sharedSymbolTable];
    id BridgeSupport = [[symbolTable symbolWithString:@"BridgeSupport"] value];
    [[BridgeSupport objectForKey:@"frameworks"] removeAllObjects];
    
    id key;
    for (int i = 0; i < 3; i++) {
        id dictionary = [BridgeSupport objectForKey:(i == 0) ? @"constants" : (i == 1) ? @"enums" : @"functions"];
        id keyEnumerator = [[dictionary allKeys] objectEnumerator];
        while ((key = [keyEnumerator nextObject])) {
            if (![symbolTable lookup:key])
                [dictionary removeObjectForKey:key];
        }
    }
}

+ (NSString *) stringValue{
    NuSymbolTable *symbolTable = [NuSymbolTable sharedSymbolTable];
    id BridgeSupport = [[symbolTable symbolWithString:@"BridgeSupport"] value];
    
    id result = [NSMutableString stringWithString:@"(global BridgeSupport\n"];
    id d, keyEnumerator, key;
    
    [result appendString:@"        (dict\n"];
    d = [BridgeSupport objectForKey:@"constants"];
    [result appendString:@"             constants:\n"];
    [result appendString:@"             (dict"];
    keyEnumerator = [[[d allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while ((key = [keyEnumerator nextObject])) {
        [result appendString:[NSString stringWithFormat:@"\n                  \"%@\" \"%@\"", key, [d objectForKey:key]]];
    }
    [result appendString:@")\n"];
    
    d = [BridgeSupport objectForKey:@"enums"];
    [result appendString:@"             enums:\n"];
    [result appendString:@"             (dict"];
    keyEnumerator = [[[d allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while ((key = [keyEnumerator nextObject])) {
        [result appendString:[NSString stringWithFormat:@"\n                  \"%@\" %@", key, [d objectForKey:key]]];
    }
    [result appendString:@")\n"];
    
    d = [BridgeSupport objectForKey:@"functions"];
    [result appendString:@"             functions:\n"];
    [result appendString:@"             (dict"];
    keyEnumerator = [[[d allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while ((key = [keyEnumerator nextObject])) {
        [result appendString:[NSString stringWithFormat:@"\n                  \"%@\" \"%@\"", key, [d objectForKey:key]]];
    }
    [result appendString:@")\n"];
    
    d = [BridgeSupport objectForKey:@"frameworks"];
    [result appendString:@"             frameworks:\n"];
    [result appendString:@"             (dict"];
    keyEnumerator = [[[d allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    while ((key = [keyEnumerator nextObject])) {
        [result appendString:[NSString stringWithFormat:@"\n                  \"%@\" \"%@\"", key, [d objectForKey:key]]];
    }
    [result appendString:@")))\n"];
    return result;
}

@end
#endif

#pragma mark - NuCell.m

@interface NuCellEnumerator ()
@property (nonatomic, strong) NuCell *cursor;
@end

@implementation NuCellEnumerator
+ (instancetype) enumeratorWithCell:(NuCell *)cell{
    NuCellEnumerator *enumerator = [NuCellEnumerator new];
    enumerator.cursor = cell;
    return enumerator;
}

- (id) nextObject{
    if (self.cursor == nil || self.cursor == [NSNull NU_null]) return nil;
    id ret = self.cursor;
    self.cursor = self.cursor.cdr;
    return ret;
}
@end



@interface NuCell ()
@property (nonatomic) int file;
@property (nonatomic) int line;
- (id) allChainedPairs:(NUCellPairBlock) block context:(NSMutableDictionary *) context;
- (id) eitherChainedPairs:(NUCellPairBlock) block context:(NSMutableDictionary *) context;
- (id) eachEvaluatedListInContext:(NSMutableDictionary *) context;


- (id) reduce:(NUAccumulationBlock) block initial:(id) initial context:(NSMutableDictionary *) context;

@end

@implementation NuCell

- (NuCellEnumerator *) cellEnumerator{
    return [NuCellEnumerator enumeratorWithCell:self];
}

+ (id) cellWithCar:(id)car cdr:(id)cdr{
    NuCell *cell = [[self alloc] init];
    [cell setCar:car];
    [cell setCdr:cdr];
    return [cell autorelease];
}

- (id) init{
    if ((self = [super init])) {
        _car = [NSNull NU_null];
        _cdr = [NSNull NU_null];
        _file = -1;
        _line = -1;
    }
    return self;
}

- (void) dealloc{
    [_car release];
    [_cdr release];
    [super dealloc];
}

- (bool) atom {return false;}

// additional accessors, for efficiency (from Nu)
- (id) caar {return [_car car];}
- (id) cadr {return [_car cdr];}
- (id) cdar {return [_cdr car];}
- (id) cddr {return [_cdr cdr];}
- (id) caaar {return [[_car car] car];}
- (id) caadr {return [[_car car] cdr];}
- (id) cadar {return [[_car cdr] car];}
- (id) caddr {return [[_car cdr] cdr];}
- (id) cdaar {return [[_cdr car] car];}
- (id) cdadr {return [[_cdr car] cdr];}
- (id) cddar {return [[_cdr cdr] car];}
- (id) cdddr {return [[_cdr cdr] cdr];}

- (BOOL) isEqual:(id) other{
    if (nu_objectIsKindOfClass(other, [NuCell class])
        && [[self car] isEqual:[other car]] && [[self cdr] isEqual:[other cdr]]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (id) first{
    return _car;
}

- (id) second{
    return [_cdr car];
}

- (id) third{
    return [[_cdr cdr] car];
}

- (id) fourth{
    return [[[_cdr cdr]  cdr] car];
}

- (id) fifth{
    return [[[[_cdr cdr]  cdr]  cdr] car];
}

- (id) nth:(int) n{
    return [self objectAtIndex:n];
}

- (id) objectAtIndex:(int) n{
    if (n < 0) return nil;
    
    NSArray *cells = [[self cellEnumerator] allObjects];
    if ([cells count] <= n) return nil;
    
    return [[cells objectAtIndex:n] car];
}

// When an unknown message is received by a cell, treat it as a call to objectAtIndex:
- (id) handleUnknownMessage:(NuCell *) method withContext:(NSMutableDictionary *) context{
    if ([[method car] isKindOfClass:[NuSymbol class]]) {
        NSString *methodName = [[method car] stringValue];
        NSUInteger length = [methodName length];
        if (([methodName characterAtIndex:0] == 'c') && ([methodName characterAtIndex:(length - 1)] == 'r')) {
            id cursor = self;
            BOOL valid = YES;
            for (int i = 1; valid && (i < length - 1); i++) {
                switch ([methodName characterAtIndex:i]) {
                    case 'd': cursor = [cursor cdr]; break;
                    case 'a': cursor = [cursor car]; break;
                    default:  valid = NO;
                }
            }
            if (valid) return cursor;
        }
    }
    id m = [[method car] evalWithContext:context];
    if ([m isKindOfClass:[NSNumber class]]) {
        int mm = [m intValue];
        if (mm < 0) {
            // if the index is negative, index from the end of the array
            mm += [self length];
        }
        return [self objectAtIndex:mm];
    }
    else {
        return [super handleUnknownMessage:method withContext:context];
    }
}

- (id) lastObject{
    return [[[[self cellEnumerator] allObjects] lastObject] car];
}

- (NSMutableString *) stringValue{
    NuCell *cursor = self;
    NSMutableString *result = [NSMutableString stringWithString:@"("];
    int count = 0;
    while (IS_NOT_NULL(cursor)) {
        if (count > 0)
            [result appendString:@" "];
        count++;
        id item = [cursor car];
        if (nu_objectIsKindOfClass(item, [NuCell class])) {
            [result appendString:[item stringValue]];
        }
        else if (IS_NOT_NULL(item)) {
            if ([item respondsToSelector:@selector(escapedStringRepresentation)]) {
                [result appendString:[item escapedStringRepresentation]];
            }
            else {
                [result appendString:[item description]];
            }
        }
        else {
            [result appendString:@"()"];
        }
        cursor = [cursor cdr];
        // check for dotted pairs
        if (IS_NOT_NULL(cursor) && !nu_objectIsKindOfClass(cursor, [NuCell class])) {
            [result appendString:@" . "];
            if ([cursor respondsToSelector:@selector(escapedStringRepresentation)]) {
                [result appendString:[((id) cursor) escapedStringRepresentation]];
            }
            else {
                [result appendString:[cursor description]];
            }
            break;
        }
    }
    [result appendString:@")"];
    return result;
}

- (NSString *) description{
    return [self stringValue];
}

- (void) addToException:(NuException*)e value:(id)value{
    const char *parsedFilename = nu_parsedFilename(self.file);
    
    if (parsedFilename) {
        NSString* filename = [NSString stringWithCString:parsedFilename encoding:NSUTF8StringEncoding];
        [e addFunction:value lineNumber:[self line] filename:filename];
    }
    else {
        [e addFunction:value lineNumber:[self line]];
    }
}


- (id) allChainedPairs:(NUCellPairBlock) block context:(NSMutableDictionary *) context{
    NSParameterAssert(block);
    NSParameterAssert([self cdr]);
    id current = [[self car] evalWithContext:context];
    
    for (id cursor in [self cellEnumerator]) {
        if ([cursor cdr] == nil || [cursor cdr] == [NSNull NU_null]) break;
        
        id next = [[[cursor cdr] car] evalWithContext:context];
        if (!block(current, next)) {
            return [context NU_false];
        }
        current = next;
    }

    return [context NU_true];
}

- (id) eitherChainedPairs:(NUCellPairBlock) block context:(NSMutableDictionary *) context{
    NSParameterAssert(block);
    NSParameterAssert([self cdr]);
    id current = [[self car] evalWithContext:context];
    
    for (id cursor in [self cellEnumerator]) {
        if ([cursor cdr] == nil || [cursor cdr] == [NSNull NU_null]) break;
        
        id next = [[[cursor cdr] car] evalWithContext:context];
        if (block(current, next)) {
            return [context NU_true];
        }
        current = next;
    }
    
    return [context NU_false];
}

- (id) evalAsPrognInContext:(NSMutableDictionary *) context{
    id value = [NSNull NU_null];
    for (id cursor in [self cellEnumerator]) {
        value = [[cursor car] evalWithContext:context];
    }
    return value;
}

- (id) eachEvaluatedListInContext:(NSMutableDictionary *) context{
    return [self map:^id(id cell, NSMutableDictionary *context) {
        return [[cell car] evalWithContext:context];
    } context:context];
}

- (id) map:(NUCellMapBlock) block context:(NSMutableDictionary *) context{
    NuCell *evaluatedArguments = nil;
    id outCursor = nil;
    
    for (id cursor in [self cellEnumerator]) {
        id nextValue = block(cursor, context);
        id newCell = [[[NuCell alloc] init] autorelease];
        [newCell setCar:nextValue];
        if (!outCursor) {
            evaluatedArguments = newCell;
        }
        else {
            [outCursor setCdr:newCell];
        }
        outCursor = newCell;
    }
    
    return evaluatedArguments;
}


- (id) evalWithContext:(NSMutableDictionary *)context{
    id value = nil;
    id result = nil;
    
    @try
    {
        value = [_car evalWithContext:context];
        
        if (NU_LIST_EVAL_BEGIN_ENABLED()) {
            if ((_line != -1) && (_file != -1)) {
                NU_LIST_EVAL_BEGIN(nu_parsedFilename(_file), _line);
            }
            else {
                NU_LIST_EVAL_BEGIN("", 0);
            }
        }
        // to improve error reporting, add the currently-evaluating expression to the context
        [context setObject:self forKey:[[NuSymbolTable sharedSymbolTable] symbolWithString:@"_expression"]];
        
        result = [value evalWithArguments:_cdr context:context];
        
        if (NU_LIST_EVAL_END_ENABLED()) {
            if ((_line != -1) && (_file != -1)) {
                NU_LIST_EVAL_END(nu_parsedFilename(_file), _line);
            }
            else {
                NU_LIST_EVAL_END("", 0);
            }
        }
    }
    @catch (NuException* nuException) {
        [self addToException:nuException value:[_car stringValue]];
        @throw nuException;
    }
    @catch (NSException* e) {
        if (   nu_objectIsKindOfClass(e, [NuBreakException class])
            || nu_objectIsKindOfClass(e, [NuContinueException class])
            || nu_objectIsKindOfClass(e, [NuReturnException class])) {
            @throw e;
        }
        else {
            NuException* nuException = [[NuException alloc] initWithName:[e name]
                                                                  reason:[e reason]
                                                                userInfo:[e userInfo]];
            [self addToException:nuException value:[_car stringValue]];
            @throw nuException;
        }
    }
    
    return result;
}

- (id) each:(id) block{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        for (id cursor in [self cellEnumerator]) {
            [args setCar:[cursor car]];
            [block evalWithArguments:args context:[NSNull NU_null]];
        }
        [args release];
    }
    return self;
}

- (id) eachPair:(id) block{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCdr:[[[NuCell alloc] init] autorelease]];
        for (id cursor in [self cellEnumerator]) {
            [args setCar:[cursor car]];
            [[args cdr] setCar:[[cursor cdr] car]];
            [block evalWithArguments:args context:[NSNull NU_null]];
        }
        [args release];
    }
    return self;
}

- (id) eachWithIndex:(id) block{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCdr:[[[NuCell alloc] init] autorelease]];
        int i = 0;
        
        for (id cursor in [self cellEnumerator]) {
            [args setCar:[cursor car]];
            [[args cdr] setCar:[NSNumber numberWithInt:i]];
            [block evalWithArguments:args context:[NSNull NU_null]];
            i++;
        }
        [args release];
    }
    return self;
}

- (id) select:(id) block{
    NuCell *parent = [[[NuCell alloc] init] autorelease];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        id resultCursor = parent;
        
        for (id cursor in [self cellEnumerator]) {
            [args setCar:[cursor car]];
            id result = [block evalWithArguments:args context:[NSNull NU_null]];
            if (nu_valueIsTrue(result)) {
                [resultCursor setCdr:[NuCell cellWithCar:[cursor car] cdr:[resultCursor cdr]]];
                resultCursor = [resultCursor cdr];
            }
        }
        [args release];
    }
    else
        return [NSNull NU_null];
    NuCell *selected = [parent cdr];
    return selected;
}

- (id) find:(id) block{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        
        for (id cursor in [self cellEnumerator]) {
            [args setCar:[cursor car]];
            id result = [block evalWithArguments:args context:[NSNull NU_null]];
            if (nu_valueIsTrue(result)) {
                [args release];
                return [cursor car];
            }
        }
        [args release];
    }
    return [NSNull NU_null];
}

- (id) map:(id) block{
    if (!nu_objectIsKindOfClass(block, [NuBlock class])) return [NSNull NU_null];

    return [self map:^id(id cell, NSMutableDictionary *context) {
        id args = [NuCell cellWithCar:[cell car] cdr:nil];
        return  [block evalWithArguments:args context:context];
    } context:[NSNull NU_null]];
}

- (id) mapSelector:(SEL) sel{
    return [self map:^id(id cell, NSMutableDictionary *context) {
        id object = [cell car];
        return [object performSelector:sel];
    } context:[NSNull NU_null]];
}

- (id) reduce:(id) block from:(id) initial{
    if (!nu_objectIsKindOfClass(block, [NuBlock class])) return initial;

    return [self reduce:^id(id sum, id obj, NSMutableDictionary *context) {
        id args = [NuCell cellWithCar:sum cdr:[NuCell cellWithCar:obj cdr:nil]];
        return [block evalWithArguments:args context:context];
    } initial:initial context:[NSNull NU_null]];
}

- (id) reduce:(NUAccumulationBlock) block initial:(id) initial context:(NSMutableDictionary *) context{
    id result = initial;
    for (id cursor in [self cellEnumerator]) {
        result = block(result, [cursor car], context);
    }
    return result;
}

- (NSUInteger) length{
    return [[[self cellEnumerator] allObjects] count];
}

- (NSMutableArray *) array{
    return [[[self cellEnumerator] allObjects] valueForKey:@"car"];
}

- (NSUInteger) count{
    return [self length];
}

- (id) comments {return nil;}

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:_car];
    [coder encodeObject:_cdr];
}

- (id) initWithCoder:(NSCoder *)coder{
    if ((self = [super init])) {
        _car = [[coder decodeObject] retain];
        _cdr = [[coder decodeObject] retain];
    }
    return self;
}

- (void) setFile:(int) f line:(int) l{
    _file = f;
    _line = l;
}

@end

@interface NuCellWithComments ()
@end

@implementation NuCellWithComments
- (void) dealloc{
    [_comments release];
    [super dealloc];
}
@end

#pragma mark - NuClass.m

// getting a specific method...
// (set x (((Convert classMethods) select: (do (m) (eq (m name) "passRect:"))) objectAtIndex:0))

@interface NuClass (){
    Class _c;
    BOOL _isRegistered;
}
@end

@implementation NuClass

+ (NuClass *) classWithName:(NSString *)string{
    const char *name = [string cStringUsingEncoding:NSUTF8StringEncoding];
    Class class = objc_getClass(name);
    if (class) {
        return [[[self alloc] initWithClass:class] autorelease];
    }
    else {
        return nil;
    }
}

+ (NuClass *) classWithClass:(Class) class{
    if (class) {
        return [[[self alloc] initWithClass:class] autorelease];
    }
    else {
        return nil;
    }
}

- (id) initWithClassNamed:(NSString *) string{
    const char *name = [string cStringUsingEncoding:NSUTF8StringEncoding];
    Class class = objc_getClass(name);
    return [self initWithClass: class];
}

- (id) initWithClass:(Class) class{
    if ((self = [super init])) {
        _c = class;
        _isRegistered = YES;                           // unless we explicitly set otherwise
    }
    return self;
}

+ (NSArray *) all{
    NSMutableArray *array = [NSMutableArray array];
    int numClasses = objc_getClassList(NULL, 0);
    if(numClasses > 0) {
        Class *classes = (Class *) malloc( sizeof(Class) * numClasses );
        objc_getClassList(classes, numClasses);
        int i = 0;
        while (i < numClasses) {
            NuClass *class = [[[NuClass alloc] initWithClass:classes[i]] autorelease];
            [array addObject:class];
            i++;
        }
        free(classes);
    }
    return array;
}

- (NSString *) name{
    //	NSLog(@"calling NuClass name for object %@", self);
    return [NSString stringWithCString:class_getName(_c) encoding:NSUTF8StringEncoding];
}

- (NSString *) stringValue{
    return [self name];
}

- (Class) wrappedClass{
    return _c;
}

- (NSArray *) classMethods{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self wrappedClass]), &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

- (NSArray *) instanceMethods{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList([self wrappedClass], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

/*! Get an array containing the names of the class methods of a class. */
- (NSArray *) classMethodNames{
    id methods = [self classMethods];
    return [methods mapSelector:@selector(name)];
}

/*! Get an array containing the names of the instance methods of a class. */
- (NSArray *) instanceMethodNames{
    id methods = [self instanceMethods];
    return [methods mapSelector:@selector(name)];
}

- (BOOL) isDerivedFromClass:(Class) parent{
    Class myclass = [self wrappedClass];
    if (myclass == parent)
        return true;
    Class superclass = [myclass superclass];
    if (superclass)
        return nu_objectIsKindOfClass(superclass, parent);
    return false;
}

- (NSComparisonResult) compare:(NuClass *) anotherClass{
    return [[self name] compare:[anotherClass name]];
}

- (NuMethod *) classMethodWithName:(NSString *) methodName{
    const char *methodNameString = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    NuMethod *method = [NSNull NU_null];
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self wrappedClass]), &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        if (!strcmp(methodNameString, sel_getName(method_getName(method_list[i])))) {
            method = [[[NuMethod alloc] initWithMethod:method_list[i]] autorelease];
        }
    }
    free(method_list);
    return method;
}

- (NuMethod *) instanceMethodWithName:(NSString *) methodName{
    const char *methodNameString = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    NuMethod *method = [NSNull NU_null];
    unsigned int method_count;
    Method *method_list = class_copyMethodList([self wrappedClass], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        if (!strcmp(methodNameString, sel_getName(method_getName(method_list[i])))) {
            method = [[[NuMethod alloc] initWithMethod:method_list[i]] autorelease];
        }
    }
    free(method_list);
    return method;
}

- (id) addInstanceMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block{
    //NSLog(@"adding instance method %@", methodName);
    return add_method_to_class(_c, methodName, signature, block);
}

- (id) addClassMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block{
    NSLog(@"adding class method %@", methodName);
    return add_method_to_class(object_getClass(_c), /* c->isa, */ methodName, signature, block);
}

- (id) addInstanceVariable:(NSString *)variableName signature:(NSString *)signature{
    //NSLog(@"adding instance variable %@", variableName);
    nu_class_addInstanceVariable_withSignature(_c, [variableName cStringUsingEncoding:NSUTF8StringEncoding], [signature cStringUsingEncoding:NSUTF8StringEncoding]);
    return [NSNull NU_null];
}

- (BOOL) isEqual:(NuClass *) anotherClass{
    return _c == anotherClass->_c;
}

- (void) setSuperclass:(NuClass *) newSuperclass{
    struct nu_objc_class
    {
        Class isa;
        Class super_class;
        // other stuff...
    };
    ((struct nu_objc_class *) self->_c)->super_class = newSuperclass->_c;
}

- (BOOL) isRegistered{
    return _isRegistered;
}

- (void) setRegistered:(BOOL) value{
    _isRegistered = value;
}

- (void) registerClass{
    if (_isRegistered == NO) {
        objc_registerClassPair(_c);
        _isRegistered = YES;
    }
}

- (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context{
    return [[self wrappedClass] handleUnknownMessage:cdr withContext:context];
}

- (NSArray *) instanceVariableNames {
    NSMutableArray *names = [NSMutableArray array];
    
    unsigned int ivarCount = 0;
    // Ivar *ivarList = class_copyIvarList(c, &ivarCount);
    
    NSLog(@"%d ivars", ivarCount);
    return names;
}

- (BOOL) addPropertyWithName:(NSString *) name {
    const objc_property_attribute_t attributes[10];
    unsigned int attributeCount = 0;
    return class_addProperty(_c, [name cStringUsingEncoding:NSUTF8StringEncoding],
                             attributes,
                             attributeCount);
}

- (NuProperty *) propertyWithName:(NSString *) name {
    objc_property_t property = class_getProperty(_c, [name cStringUsingEncoding:NSUTF8StringEncoding]);
    
    return [NuProperty propertyWithProperty:(objc_property_t) property];
}

- (NSArray *) properties {
    unsigned int property_count;
    objc_property_t *property_list = class_copyPropertyList(_c, &property_count);
    
    NSMutableArray *properties = [NSMutableArray array];
    for (int i = 0; i < property_count; i++) {
        [properties addObject:[NuProperty propertyWithProperty:property_list[i]]];
    }
    free(property_list);
    return properties;
}

//OBJC_EXPORT objc_property_t class_getProperty(Class cls, const char *name)


@end

#pragma mark - NuEnumerable.m

@interface NuEnumerable(Unimplemented)
- (id) objectEnumerator;
@end

@implementation NuEnumerable

- (id) each:(id) callable{
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        for (id object in [self objectEnumerator]) {
            @try
            {
                [args setCar:object];
                [callable evalWithArguments:args context:nil];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                [args release];
                @throw(exception);
            }
            
        }
    }
    [args release];
    return self;
}

- (id) eachWithIndex:(NuBlock *) block{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        int i = 0;
        for (id object in [self objectEnumerator]) {
            @try
            {
                [args setCar:object];
                [[args cdr] setCar:[NSNumber numberWithInt:i]];
                [block evalWithArguments:args context:nil];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                [args release];
                @throw(exception);
            }
            i++;
        }
    }
    [args release];
    return self;
}

- (NSArray *) select{
    NSMutableArray *selected = [NSMutableArray array];
    for (id object in [self objectEnumerator]) {
        if (nu_valueIsTrue(object)) {
            [selected addObject:object];
        }
    }
    return selected;
}

- (NSArray *) select:(NuBlock *) block{
    NSMutableArray *selected = [NSMutableArray array];
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        for (id object in [self objectEnumerator]) {
            [args setCar:object];
            id result = [block evalWithArguments:args context:[NSNull NU_null]];
            if (nu_valueIsTrue(result)) {
                [selected addObject:object];
            }
        }
    }
    [args release];
    return selected;
}

- (id) find:(NuBlock *) block{
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        for (id object in [self objectEnumerator]) {
            [args setCar:object];
            id result = [block evalWithArguments:args context:[NSNull NU_null]];
            if (nu_valueIsTrue(result)) {
                [args release];
                return object;
            }
        }
    }
    [args release];
    return [NSNull NU_null];
}

- (NSArray *) map:(id) callable{
    NSMutableArray *results = [NSMutableArray array];
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        for (id object in [self objectEnumerator]) {
            [args setCar:object];
            [results addObject:[callable evalWithArguments:args context:nil]];
        }
    }
    [args release];
    return results;
}

- (NSArray *) mapWithIndex:(id) callable{
    NSMutableArray *results = [NSMutableArray array];
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        int i = 0;
        for (id object in [self objectEnumerator]) {
            [args setCar:object];
            [[args cdr] setCar:[NSNumber numberWithInt:i]];
            [results addObject:[callable evalWithArguments:args context:nil]];
            i++;
        }
    }
    [args release];
    return results;
}

- (NSArray *) mapSelector:(SEL) sel{
    NSMutableArray *results = [NSMutableArray array];
    for (id object in [self objectEnumerator]) {
        [results addObject:[object performSelector:sel]];
    }
    return results;
}

- (id) reduce:(id) callable from:(id) initial{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        for (id object in [self objectEnumerator]) {
            [args setCar:result];
            [[args cdr] setCar: object];
            result = [callable evalWithArguments:args context:nil];
        }
    }
    [args release];
    return result;
}

- (id) maximum:(NuBlock *) block{
    id bestObject = nil;
    
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        for (id object in [self objectEnumerator]) {
            if (!bestObject) {
                bestObject = object;
            }
            else {
                [args setCar:object];
                [[args cdr] setCar:bestObject];
                id result = [block evalWithArguments:args context:[NSNull NU_null]];
                if (result && (result != [NSNull NU_null])) {
                    if ([result intValue] > 0) {
                        bestObject = object;
                    }
                }
            }
        }
    }
    [args release];
    return bestObject;
}

@end


#pragma mark - NuException.m

#define kFilenameTopLevel @"<TopLevel>"

@implementation NSException (NuStackTrace)

- (NSString*)dump{
    NSMutableString* dump = [NSMutableString stringWithString:@""];
    
    // Print the system stack trace (10.6 only)
    if ([self respondsToSelector:@selector(callStackSymbols)])
    {
        [dump appendString:@"\nSystem stack trace:\n"];
        
        NSArray* callStackSymbols = [self callStackSymbols];
        NSUInteger count = [callStackSymbols count];
        for (int i = 0; i < count; i++)
        {
            [dump appendString:[callStackSymbols objectAtIndex:i]];
            [dump appendString:@"\n"];
        }
    }
    
    return dump;
}

@end


static void Nu_defaultExceptionHandler(NSException* e){
    [e dump];
}

static BOOL NuException_verboseExceptionReporting = NO;

@interface NuException (){
    NSMutableArray* _stackTrace;
}
@end

@implementation NuException

+ (void)setDefaultExceptionHandler{
    NSSetUncaughtExceptionHandler(*Nu_defaultExceptionHandler);
    
#ifdef IMPORT_EXCEPTION_HANDLING_FRAMEWORK
    [[NSExceptionHandler defaultExceptionHandler]
     setExceptionHandlingMask:(NSHandleUncaughtExceptionMask
                               | NSHandleUncaughtSystemExceptionMask
                               | NSHandleUncaughtRuntimeErrorMask
                               | NSHandleTopLevelExceptionMask
                               | NSHandleOtherExceptionMask)];
#endif
}

+ (void)setVerbose:(BOOL)flag{
    NuException_verboseExceptionReporting = flag;
}


- (void) dealloc{
    if (_stackTrace)
    {
        [_stackTrace removeAllObjects];
        [_stackTrace release];
    }
    [super dealloc];
}

- (id)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo{
    self = [super initWithName:name reason:reason userInfo:userInfo];
    _stackTrace = [[NSMutableArray alloc] init];
    return self;
}

- (NSArray*)stackTrace{
    return _stackTrace;
}

- (NuException *)addFunction:(NSString *)function lineNumber:(int)line{
    return [self addFunction:function lineNumber:line filename:kFilenameTopLevel];
}

- (NuException *)addFunction:(NSString *)function lineNumber:(int)line filename:(NSString *)filename{
    NuTraceInfo* traceInfo = [[[NuTraceInfo alloc] initWithFunction:function
                                                         lineNumber:line
                                                           filename:filename]
                              autorelease];
    [_stackTrace addObject:traceInfo];
    
    return self;
}

- (NSString *)stringValue{
    return [self reason];
}


- (NSString*)dumpExcludingTopLevelCount:(NSUInteger)topLevelCount{
    NSMutableString* dump = [NSMutableString stringWithString:@"Nu uncaught exception: "];
    
    [dump appendString:[NSString stringWithFormat:@"%@: %@\n", [self name], [self reason]]];
    
    NSUInteger count = [_stackTrace count] - topLevelCount;
    for (int i = 0; i < count; i++)
    {
        NuTraceInfo* trace = [_stackTrace objectAtIndex:i];
        
        NSString* traceString = [NSString stringWithFormat:@"  from %@:%d: in %@\n",
                                 [trace filename],
                                 [trace lineNumber],
                                 [trace function]];
        
        [dump appendString:traceString];
    }
    
    if (NuException_verboseExceptionReporting)
    {
        [dump appendString:[super dump]];
    }
    
    return dump;
}

- (NSString*)dump{
    return [self dumpExcludingTopLevelCount:0];
}

@end

@interface NuTraceInfo (){
    NSString*   _filename;
    int         _lineNumber;
    NSString*   _function;
}
@end

@implementation NuTraceInfo

- (id)initWithFunction:(NSString *)aFunction lineNumber:(int)aLine filename:(NSString *)aFilename{
    self = [super init];
    
    if (self)
    {
        _filename = [aFilename retain];
        _lineNumber = aLine;
        _function = [aFunction retain];
    }
    return self;
}

- (void)dealloc{
    [_filename release];
    [_function release];
    
    [super dealloc];
}

- (NSString *)filename{
    return _filename;
}

- (int)lineNumber{
    return _lineNumber;
}

- (NSString *)function{
    return _function;
}

@end

#pragma mark - NuExtensions.m

@implementation NSNull(Nu)
- (bool) atom{
    return true;
}

- (NSUInteger) length{
    return 0;
}

- (NSUInteger) count{
    return 0;
}

- (NSMutableArray *) array{
    return [NSMutableArray array];
}

- (NSString *) stringValue{
    return @"()";
}

- (BOOL) isEqual:(id) other{
    return ((self == other) || (other == 0)) ? 1l : 0l;
}

- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding{
    return [[self stringValue] cStringUsingEncoding:encoding];
}

- (id) eachEvaluatedListInContext:(NSMutableArray *) context{
    return nil;
}

- (id) cellEnumerator{
    return nil;
}

- (id) evalAsPrognInContext:(NSMutableDictionary *) context{
    return nil;
}

- (id) map:(NUCellMapBlock) block context:(NSMutableDictionary *) context{
    return nil;
}

@end

@implementation NSArray(Nu)
+ (NSArray *) arrayWithList:(id) list{
    return [[list array] mutableCopy] ?: [NSMutableArray array];
}

// When an unknown message is received by an array, treat it as a call to objectAtIndex:
- (id) handleUnknownMessage:(NuCell *) method withContext:(NSMutableDictionary *) context{
    id m = [[method car] evalWithContext:context];
    if ([m isKindOfClass:[NSNumber class]]) {
        int mm = [m intValue];
        if (mm < 0) {
            // if the index is negative, index from the end of the array
            mm += [self count];
        }
        if ((mm < [self count]) && (mm >= 0)) {
            return [self objectAtIndex:mm];
        }
        else {
            return [NSNull NU_null];
        }
    }
    else {
        return [super handleUnknownMessage:method withContext:context];
    }
}

// This default sort method sorts an array using its elements' compare: method.
- (NSArray *) sort{
    return [self sortedArrayUsingSelector:@selector(compare:)];
}

// Convert an array into a list.
- (NuCell *) list{
    NSUInteger count = [self count];
    if (count == 0)
        return nil;
    NuCell *result = [[[NuCell alloc] init] autorelease];
    NuCell *cursor = result;
    [result setCar:[self objectAtIndex:0]];
    for (int i = 1; i < count; i++) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        [cursor setCar:[self objectAtIndex:i]];
    }
    return result;
}

- (id) reduceLeft:(id)callable from:(id) initial{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        for (NSInteger i = [self count] - 1; i >= 0; i--) {
            id object = [self objectAtIndex:i];
            [args setCar:result];
            [[args cdr] setCar: object];
            result = [callable evalWithArguments:args context:nil];
        }
    }
    [args release];
    return result;
}

- (id) eachInReverse:(id) callable{
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        for (id object in [self reverseObjectEnumerator]) {
            @try
            {
                [args setCar:object];
                [callable evalWithArguments:args context:nil];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                @throw(exception);
            }
        }
    }
    [args release];
    return self;
}

static NSComparisonResult sortedArrayUsingBlockHelper(id a, id b, void *context){
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    [args setCar:a];
    [[args cdr] setCar:b];
    
    // cast context as a block
    NuBlock *block = (NuBlock *)context;
    id result = [block evalWithArguments:args context:nil];
    
    [args release];
    return [result intValue];
}

- (NSArray *) sortedArrayUsingBlock:(NuBlock *) block{
    return [self sortedArrayUsingFunction:sortedArrayUsingBlockHelper context:block];
}

@end

@implementation NSMutableArray(Nu)

- (void) addObjectsFromList:(id)list{
    [self addObjectsFromArray:[NSArray arrayWithList:list]];
}

- (void) addPossiblyNullObject:(id)anObject{
    [self addObject:((anObject == nil) ?  [NSNull NU_null] : anObject)];
}

- (void) insertPossiblyNullObject:(id)anObject atIndex:(int)index{
    [self insertObject:((anObject == nil) ? [NSNull NU_null] : anObject) atIndex:index];
}

- (void) replaceObjectAtIndex:(int)index withPossiblyNullObject:(id)anObject{
    [self replaceObjectAtIndex:index withObject:((anObject == nil) ? [NSNull NU_null] : anObject)];
}

- (void) sortUsingBlock:(NuBlock *) block{
    [self sortUsingFunction:sortedArrayUsingBlockHelper context:block];
}

@end

@implementation NSSet(Nu)
+ (NSSet *) setWithList:(id) list{
    NSArray *array = [list array] ?: [NSMutableArray array];
    return [[NSSet setWithArray:array] mutableCopy];
}

// Convert a set into a list.
- (NuCell *) list{
    NSEnumerator *setEnumerator = [self objectEnumerator];
    NSObject *anObject = [setEnumerator nextObject];
    
    if(!anObject)
        return nil;
    
    NuCell *result = [[[NuCell alloc] init] autorelease];
    NuCell *cursor = result;
    [cursor setCar:anObject];
    
    while ((anObject = [setEnumerator nextObject])) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        [cursor setCar:anObject];
    }
    return result;
}

@end

@implementation NSMutableSet(Nu)

- (void) addPossiblyNullObject:(id)anObject{
    [self addObject:((anObject == nil) ? [NSNull NU_null] : anObject)];
}

@end

@implementation NSDictionary(Nu)

+ (NSDictionary *) dictionaryWithList:(id) list{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    id cursor = list;
    while (cursor && (cursor != [NSNull NU_null]) && ([cursor cdr]) && ([cursor cdr] != [NSNull NU_null])) {
        id key = [cursor car];
        if ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) {
            key = [key labelName];
        }
        id value = [[cursor cdr] car];
        if (!value || [value isEqual:[NSNull null]]) {
            [d removeObjectForKey:key];
        } else {
            [d setValue:value forKey:key];
        }
        cursor = [[cursor cdr] cdr];
    }
    return d;
}

- (id) objectForKey:(id)key withDefault:(id)defaultValue{
    id value = [self objectForKey:key];
    return value ? value : defaultValue;
}

// When an unknown message is received by a dictionary, treat it as a call to objectForKey:
- (id) handleUnknownMessage:(NuCell *) method withContext:(NSMutableDictionary *) context{
    id cursor = method;
    while (cursor && (cursor != [NSNull NU_null]) && ([cursor cdr]) && ([cursor cdr] != [NSNull NU_null])) {
        id key = [cursor car];
        id value = [[cursor cdr] car];
        if ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) {
            id evaluated_key = [key labelName];
            id evaluated_value = [value evalWithContext:context];
            [self setValue:evaluated_value forKey:evaluated_key];
        }
        else {
            id evaluated_key = [key evalWithContext:context];
            id evaluated_value = [value evalWithContext:context];
            [self setValue:evaluated_value forKey:evaluated_key];
        }
        cursor = [[cursor cdr] cdr];
    }
    if (cursor && (cursor != [NSNull NU_null])) {
        // if the method is a label, use its value as the key.
        if ([[cursor car] isKindOfClass:[NuSymbol class]] && ([[cursor car] isLabel])) {
            id result = [self objectForKey:[[cursor car] labelName]];
			return result ? result : [NSNull NU_null];
        }
        else {
            id result = [self objectForKey:[[cursor car] evalWithContext:context]];
			return result ? result : [NSNull NU_null];
        }
    }
    else {
        return [NSNull NU_null];
    }
}

// Iterate over the key-object pairs in a dictionary. Pass it a block with two arguments: (key object).
- (id) each:(id) block{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    for (id key in [[self allKeys] objectEnumerator]) {
        @try
        {
            [args setCar:key];
            [[args cdr] setCar:[self objectForKey:key]];
            [block evalWithArguments:args context:[NSNull NU_null]];
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
    }
    [args release];
    return self;
}

- (NSDictionary *) map: (id) callable{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        for (id object in [self keyEnumerator]) {
            [args setCar:object];
            [args setCdr:[[[NuCell alloc] init] autorelease]];
            [[args cdr] setCar:[self objectForKey:object]];
            [results setObject:[callable evalWithArguments:args context:nil] forKey:object];
        }
    }
    [args release];
    return results;
}

@end

@implementation NSMutableDictionary(Nu)
- (id) lookupObjectForKey:(id)key{
    id object = [self objectForKey:key];
    if (object) return object;
    id parent = [self objectForKey:PARENT_KEY];
    if (!parent) return nil;
    return [parent lookupObjectForKey:key];
}

- (void) setPossiblyNullObject:(id) anObject forKey:(id) aKey{
    [self setObject:((anObject == nil) ? [NSNull NU_null] : anObject) forKey:aKey];
}

@end

@interface NuStringEnumerator : NSEnumerator{
    NSString *_string;
    int _index;
}
@end

@implementation NuStringEnumerator

+ (NuStringEnumerator *) enumeratorWithString:(NSString *) string{
    return [[[self alloc] initWithString:string] autorelease];
}

- (id) initWithString:(NSString *) s{
    self = [super init];
    _string = [s retain];
    _index = 0;
    return self;
}

- (id) nextObject {
    if (_index < [_string length]) {
        return [NSNumber numberWithInt:[_string characterAtIndex:_index++]];
    } else {
        return nil;
    }
}

- (void) dealloc {
    [_string release];
    [super dealloc];
}

@end

@implementation NSString(Nu)
- (NSString *) stringValue{
    return self;
}

- (NSString *) escapedStringRepresentation{
    NSMutableString *result = [NSMutableString stringWithString:@"\""];
    NSUInteger length = [self length];
    for (int i = 0; i < length; i++) {
        unichar c = [self characterAtIndex:i];
        if (c < 32) {
            switch (c) {
                case 0x07: [result appendString:@"\\a"]; break;
                case 0x08: [result appendString:@"\\b"]; break;
                case 0x09: [result appendString:@"\\t"]; break;
                case 0x0a: [result appendString:@"\\n"]; break;
                case 0x0c: [result appendString:@"\\f"]; break;
                case 0x0d: [result appendString:@"\\r"]; break;
                case 0x1b: [result appendString:@"\\e"]; break;
                default:
                    [result appendFormat:@"\\x%02x", c];
            }
        }
        else if (c == '"') {
            [result appendString:@"\\\""];
        }
        else if (c == '\\') {
            [result appendString:@"\\\\"];
        }
        else if (c < 127) {
            [result appendCharacter:c];
        }
        else if (c < 256) {
            [result appendFormat:@"\\x%02x", c];
        }
        else {
            [result appendFormat:@"\\u%04x", c];
        }
    }
    [result appendString:@"\""];
    return result;
}

- (id) evalWithContext:(NSMutableDictionary *) context{
    NSMutableString *result;
    NSArray *components = [self componentsSeparatedByString:@"#{"];
    if ([components count] == 1) {
        result = [NSMutableString stringWithString:self];
    }
    else {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
        result = [NSMutableString stringWithString:[components objectAtIndex:0]];
        int i;
        for (i = 1; i < [components count]; i++) {
            NSArray *parts = [[components objectAtIndex:i] componentsSeparatedByString:@"}"];
            NSString *expression = [parts objectAtIndex:0];
            // evaluate each expression
            if (expression) {
                id body;
                @synchronized(parser) {
                    body = [parser parse:expression];
                }
                id value = [body evalWithContext:context];
                NSString *stringValue = [value stringValue];
                [result appendString:stringValue];
            }
            [result appendString:[parts objectAtIndex:1]];
            int j = 2;
            while (j < [parts count]) {
                [result appendString:@"}"];
                [result appendString:[parts objectAtIndex:j]];
                j++;
            }
        }
    }
    return result;
}

+ (id) carriageReturn{
    return [self stringWithCString:"\n" encoding:NSUTF8StringEncoding];
}

#if !TARGET_OS_IPHONE

// Read the text output of a shell command into a string and return the string.
+ (NSString *) stringWithShellCommand:(NSString *) command{
    return [self stringWithShellCommand:command standardInput:nil];
}

+ (NSString *) stringWithShellCommand:(NSString *) command standardInput:(id) input{
    NSData *data = [NSData dataWithShellCommand:command standardInput:input];
    return data ? [[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] chomp] : nil;
}
#endif

+ (NSString *) stringWithData:(NSData *) data encoding:(int) encoding{
    return [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
}

// Read the contents of standard input into a string.
+ (NSString *) stringWithStandardInput{
    return [[[NSString alloc] initWithData:[NSData dataWithStandardInput] encoding:NSUTF8StringEncoding] autorelease];
}

// If the last character is a newline, delete it.
- (NSString *) chomp{
    NSInteger lastIndex = [self length] - 1;
    if (lastIndex >= 0) {
        if ([self characterAtIndex:lastIndex] == 10) {
            return [self substringWithRange:NSMakeRange(0, lastIndex)];
        }
        else {
            return self;
        }
    }
    else {
        return self;
    }
}

+ (NSString *) stringWithCharacter:(unichar) c{
    return [self stringWithFormat:@"%C", c];
}

// Convert a string into a symbol.
- (id) symbolValue{
    return [[NuSymbolTable sharedSymbolTable] symbolWithString:self];
}

// Split a string into lines.
- (NSArray *) lines{
    NSArray *a = [self componentsSeparatedByString:@"\n"];
    if ([[a lastObject] isEqualToString:@""]) {
        return [a subarrayWithRange:NSMakeRange(0, [a count]-1)];
    }
    else {
        return a;
    }
}

// Replace a substring with another.
- (NSString *) replaceString:(NSString *) target withString:(NSString *) replacement{
    NSMutableString *s = [NSMutableString stringWithString:self];
    [s replaceOccurrencesOfString:target withString:replacement options:0 range:NSMakeRange(0, [self length])];
    return s;
}

- (id) objectEnumerator{
    return [NuStringEnumerator enumeratorWithString:self];
}

- (id) each:(id) block{
    id args = [[NuCell alloc] init];
    NSEnumerator *characterEnumerator = [self objectEnumerator];
    id character;
    while ((character = [characterEnumerator nextObject])) {
        @try
        {
            [args setCar:character];
            [block evalWithArguments:args context:[NSNull NU_null]];
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
    }
    [args release];
    return self;
}

@end

@implementation NSMutableString(Nu)
- (void) appendCharacter:(unichar) c{
    [self appendFormat:@"%C", c];
}

@end

@implementation NSData(Nu)

- (const unsigned char) byteAtIndex:(int) i{
	const unsigned char buffer[2];
	[self getBytes:(void *)&buffer range:NSMakeRange(i,1)];
	return buffer[0];
}

#if !TARGET_OS_IPHONE
// Read the output of a shell command into an NSData object and return the object.
+ (NSData *) dataWithShellCommand:(NSString *) command{
    return [self dataWithShellCommand:command standardInput:nil];
}

+ (NSData *) dataWithShellCommand:(NSString *) command standardInput:(id) input{
    char *input_template = strdup("/tmp/nuXXXXXX");
    char *input_filename = mktemp(input_template);
    char *output_template = strdup("/tmp/nuXXXXXX");
    char *output_filename = mktemp(output_template);
    id returnValue = nil;
    if (input_filename || output_filename) {
        NSString *inputFileName = [NSString stringWithCString:input_filename encoding:NSUTF8StringEncoding];
        NSString *outputFileName = [NSString stringWithCString:output_filename encoding:NSUTF8StringEncoding];
        NSString *fullCommand;
        if (input) {
            if ([input isKindOfClass:[NSData class]]) {
                [input writeToFile:inputFileName atomically:NO];
            } else if ([input isKindOfClass:[NSString class]]) {
                [input writeToFile:inputFileName atomically:NO encoding:NSUTF8StringEncoding error:nil];
            } else {
                [[input stringValue] writeToFile:inputFileName atomically:NO encoding:NSUTF8StringEncoding error:nil];
            }
            fullCommand = [NSString stringWithFormat:@"%@ < %@ > %@", command, inputFileName, outputFileName];
        }
        else {
            fullCommand = [NSString stringWithFormat:@"%@ > %@", command, outputFileName];
        }
        const char *commandString = [[fullCommand stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
        int result = system(commandString) >> 8;  // this needs an explanation
        if (!result)
            returnValue = [NSData dataWithContentsOfFile:outputFileName];
        system([[NSString stringWithFormat:@"rm -f %@ %@", inputFileName, outputFileName] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    free(input_template);
    free(output_template);
    return returnValue;
}
#endif

// Read the contents of standard input into a string.
+ (NSData *) dataWithStandardInput{
    return [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
}

// Helper. Included because it's so useful.
- (id) propertyListValue {
    return [NSPropertyListSerialization propertyListWithData:self
                                                     options:NSPropertyListImmutable
                                                      format:nil
                                                       error:nil];
}

@end

@implementation NSNumber(Nu)

- (id) times:(id) block{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        int x = [self intValue];
        int i;
        for (i = 0; i < x; i++) {
            @try
            {
                @autoreleasepool {
                    [args setCar:[NSNumber numberWithInt:i]];
                    [block evalWithArguments:args context:[NSNull NU_null]];
                }
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                @throw(exception);
            }
        }
        [args release];
    }
    return self;
}

- (id) downTo:(id) number do:(id) block{
    int startValue = [self intValue];
    int finalValue = [number intValue];
    if (startValue < finalValue) {
        return self;
    }
    else {
        id args = [[NuCell alloc] init];
        if (nu_objectIsKindOfClass(block, [NuBlock class])) {
            int i;
            for (i = startValue; i >= finalValue; i--) {
                @try
                {
                    [args setCar:[NSNumber numberWithInt:i]];
                    [block evalWithArguments:args context:[NSNull NU_null]];
                }
                @catch (NuBreakException *exception) {
                    break;
                }
                @catch (NuContinueException *exception) {
                    // do nothing, just continue with the next loop iteration
                }
                @catch (id exception) {
                    @throw(exception);
                }
            }
        }
        [args release];
    }
    return self;
}

- (id) upTo:(id) number do:(id) block{
    int startValue = [self intValue];
    int finalValue = [number intValue];
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        int i;
        for (i = startValue; i <= finalValue; i++) {
            @try
            {
                [args setCar:[NSNumber numberWithInt:i]];
                [block evalWithArguments:args context:[NSNull NU_null]];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                @throw(exception);
            }
        }
    }
    [args release];
    return self;
}

- (NSString *) hexValue{
    int x = [self intValue];
    return [NSString stringWithFormat:@"0x%x", x];
}

@end

@implementation NuMath

+ (double) cos: (double) x {return cos(x);}
+ (double) sin: (double) x {return sin(x);}
+ (double) sqrt: (double) x {return sqrt(x);}
+ (double) cbrt: (double) x {return cbrt(x);}
+ (double) square: (double) x {return x*x;}
+ (double) exp: (double) x {return exp(x);}
+ (double) exp2: (double) x {return exp2(x);}
+ (double) log: (double) x {return log(x);}

#ifdef FREEBSD
+ (double) log2: (double) x {return log10(x)/log10(2.0);} // not in FreeBSD
#else
+ (double) log2: (double) x {return log2(x);}
#endif

+ (double) log10: (double) x {return log10(x);}

+ (double) floor: (double) x {return floor(x);}
+ (double) ceil: (double) x {return ceil(x);}
+ (double) round: (double) x {return round(x);}

+ (double) raiseNumber: (double) x toPower: (double) y {return pow(x, y);}
+ (int) integerDivide:(int) x by:(int) y {return x / y;}
+ (int) integerMod:(int) x by:(int) y {return x % y;}

+ (double) abs: (double) x {return (x < 0) ? -x : x;}

+ (long) random{
    long r = random();
    return r;
}

+ (void) srandom:(unsigned long) seed{
    srandom((unsigned int) seed);
}

@end

@implementation NSDate(Nu)

+ dateWithTimeIntervalSinceNow:(NSTimeInterval) seconds{
    return [[[NSDate alloc] initWithTimeIntervalSinceNow:seconds] autorelease];
}

@end

@implementation NSFileManager(Nu)

// crashes
+ (id) _timestampForFileNamed:(NSString *) filename{
    if (filename == [NSNull NU_null]) return nil;
	NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager]
								attributesOfItemAtPath:[filename stringByExpandingTildeInPath]
								error:&error];
    return [attributes valueForKey:NSFileModificationDate];
}

+ (id) creationTimeForFileNamed:(NSString *) filename{
    if (!filename)
        return nil;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:sb.st_ctimespec.tv_sec];
}

+ (id) modificationTimeForFileNamed:(NSString *) filename{
    if (!filename)
        return nil;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:sb.st_mtimespec.tv_sec];
}

+ (int) directoryExistsNamed:(NSString *) filename{
    if (!filename)
        return NO;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) != 0) ? 1 : 0;
}

+ (int) fileExistsNamed:(NSString *) filename{
    if (!filename)
        return NO;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) == 0) ? 1 : 0;
}

@end

@implementation NSBundle(Nu)

+ (NSBundle *) frameworkWithName:(NSString *) frameworkName{
    NSBundle *framework = nil;
    
    // is the framework already loaded?
    NSArray *fw = [NSBundle allFrameworks];
    NSEnumerator *frameworkEnumerator = [fw objectEnumerator];
    while ((framework = [frameworkEnumerator nextObject])) {
        if ([frameworkName isEqual: [[framework infoDictionary] objectForKey:@"CFBundleName"]]) {
            return framework;
        }
    }
    
    // first try the current directory
    framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@.framework", [[NSFileManager defaultManager] currentDirectoryPath], frameworkName]];
    
    // then /Library/Frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/Frameworks/%@.framework", frameworkName]];
    
    // then /System/Library/Frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework", frameworkName]];
    
    // then /usr/frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/usr/frameworks/%@.framework", frameworkName]];
    
    // then /usr/local/frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/usr/local/frameworks/%@.framework", frameworkName]];
    
    if (framework) {
        if ([framework load])
            return framework;
    }
    return nil;
}

- (id) loadNuFile:(NSString *) nuFileName withContext:(NSMutableDictionary *) context{
    NSString *fileName = [self pathForResource:nuFileName ofType:@"nu"];
    if (fileName) {
        NSString *string = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
        if (string) {
            NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
            id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
            id body = [parser parse:string asIfFromFilename:[fileName cStringUsingEncoding:NSUTF8StringEncoding]];
            [body evalWithContext:context];
            return [symbolTable symbolWithString:@"t"];
        }
        return nil;
    }
    else {
        return nil;
    }
}

@end


@implementation NSMethodSignature(Nu)

- (NSString *) typeString{
    // in 10.5, we can do this:
    // return [self _typeString];
    NSMutableString *result = [NSMutableString stringWithFormat:@"%s", [self methodReturnType]];
    NSInteger i;
    NSUInteger max = [self numberOfArguments];
    for (i = 0; i < max; i++) {
        [result appendFormat:@"%s", [self getArgumentTypeAtIndex:i]];
    }
    return result;
}

@end


#pragma mark - NuHandler.m

static id collect_arguments(struct nu_handler_description *description, va_list ap){
    int i = 0;
    char *type;
    id arguments = [[NuCell alloc] init];
    id cursor = arguments;
    while((type = description->description[2+i])) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        // NSLog(@"argument type %d: %s", i, type);
        if (!strcmp(type, "@")) {
            [cursor setCar:va_arg(ap, id)];
        }
        else if (!strcmp(type, "i")) {
            int x = va_arg(ap, int);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "C")) {
            // unsigned char is promoted to int in va_arg()
            //unsigned char x = va_arg(ap, unsigned char);
            int x = va_arg(ap, int);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "f")) {
            // calling this w/ float crashes on intel
            double x = (double) va_arg(ap, double);
            //NSLog(@"argument is %f", *((float *) &x));
            ap = ap - sizeof(float);              // messy, messy...
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "d")) {
            double x = va_arg(ap, double);
            //NSLog(@"argument is %lf", x);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, ":")) {
            SEL x = va_arg(ap, SEL);
            //NSLog(@"collect_arguments: [:] (SEL) = %@", NSStringFromSelector(x));
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "^@")) {
            void *x = va_arg(ap, void *);
            //NSLog(@"argument is %lf", x);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
#if TARGET_OS_IPHONE
        else if (!strcmp(type, "{CGRect={CGPoint=ff}{CGSize=ff}}")
                 || (!strcmp(type, "{CGRect=\"origin\"{CGPoint=\"x\"f\"y\"f}\"size\"{CGSize=\"width\"f\"height\"f}}"))) {
            CGRect x = va_arg(ap, CGRect);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
#else
        else if (!strcmp(type, "{_NSRect={_NSPoint=dd}{_NSSize=dd}}")) {
            NSRect x = va_arg(ap, NSRect);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{CGRect={CGPoint=dd}{CGSize=dd}}")) {
            CGRect x = va_arg(ap, CGRect);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{_NSPoint=dd}")) {
            NSPoint x = va_arg(ap, NSPoint);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{_NSSize=dd}")) {
            NSSize x = va_arg(ap, NSSize);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{_NSRange=QQ}")) {
            NSRange x = va_arg(ap, NSRange);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
#endif
        else {
            NSLog(@"unsupported argument type %s, see objc/handler.m to add support for it", type);
        }
        i++;
    }
    return arguments;
}

// helper function called by method handlers
static void nu_handler(void *return_value, struct nu_handler_description *handler, id receiver, va_list ap){
    id result;
    BOOL retained_through_autorelease = NO;
    @autoreleasepool {
        NuBlock *block = (NuBlock *) handler->description[1];
        // NSLog(@"handling %@", [block stringValue]);
        id arguments = collect_arguments(handler, ap);
        result = [block evalWithArguments:[arguments cdr] context:nil self:receiver];
        if (return_value) {
            // if the call returns an object, retain the result so that it will survive the autorelease.
            // we undo this retain once we're safely outside of the autorelease block.
            if (handler->description[0][1] == '@') {
                retained_through_autorelease = YES;
                [result retain];
                // if the call is supposed to return a retained object, add an additional retain.
                if (handler->description[0][0] == '!') {
                    // The static analyzer says this is a potential leak.
                    // It's intentional, we are returning from a method that should return a retained (+1) object.
                    [result retain];
                }
            }
            set_objc_value_from_nu_value(return_value, result, handler->description[0]+1);
        }
        [arguments release];
    }
    if (retained_through_autorelease) {
        // undo the object-preserving retain we made in the autorelease block above.
        [result autorelease];
    }
}

@interface NuHandlers : NSObject{
@public
    struct nu_handler_description *_handlers;
    int _handler_count;
    int _next_free_handler;
}

@end

@implementation NuHandlers
- (id) initWithHandlers:(struct nu_handler_description *) h count:(int) count{
    if ((self = [super init])) {
        _handlers = h;
        _handler_count = count;
        _next_free_handler = 0;
    }
    return self;
}

@end

static IMP handler_returning_void(void *userdata) {
    return imp_implementationWithBlock(^(id receiver, ...) {
        struct nu_handler_description description;
        description.handler = NULL;
        description.description = userdata;
        va_list ap;
        va_start(ap, receiver);
        nu_handler(0, &description, receiver, ap);
    });
}

#define MAKE_HANDLER_WITH_TYPE(type) \
static IMP handler_returning_ ## type (void* userdata) \
{ \
return imp_implementationWithBlock(^(id receiver, ...) { \
struct nu_handler_description description; \
description.handler = NULL; \
description.description = userdata; \
va_list ap; \
va_start(ap, receiver); \
type result; \
nu_handler(&result, &description, receiver, ap); \
return result; \
}); \
}

MAKE_HANDLER_WITH_TYPE(id)
MAKE_HANDLER_WITH_TYPE(int)
MAKE_HANDLER_WITH_TYPE(bool)
MAKE_HANDLER_WITH_TYPE(float)
MAKE_HANDLER_WITH_TYPE(double)
MAKE_HANDLER_WITH_TYPE(CGRect)
MAKE_HANDLER_WITH_TYPE(CGPoint)
MAKE_HANDLER_WITH_TYPE(CGSize)
#if !TARGET_OS_IPHONE
MAKE_HANDLER_WITH_TYPE(NSRect)
MAKE_HANDLER_WITH_TYPE(NSPoint)
MAKE_HANDLER_WITH_TYPE(NSSize)
#endif
MAKE_HANDLER_WITH_TYPE(NSRange)

static NSMutableDictionary *handlerWarehouse = nil;

@implementation NuHandlerWarehouse

+ (void) registerHandlers:(struct nu_handler_description *) description withCount:(int) count forReturnType:(NSString *) returnType{
    if (!handlerWarehouse) {
        handlerWarehouse = [[NSMutableDictionary alloc] init];
    }
    NuHandlers *handlers = [[NuHandlers alloc] initWithHandlers:description count:count];
    [handlerWarehouse setObject:handlers forKey:returnType];
    [handlers release];
}

+ (IMP) handlerWithSelector:(SEL)sel block:(NuBlock *)block signature:(const char *) signature userdata:(char **) userdata{
    NSString *returnType = [NSString stringWithCString:userdata[0]+1 encoding:NSUTF8StringEncoding];
    if ([returnType isEqualToString:@"v"]) {
        return handler_returning_void(userdata);
    }
    else if ([returnType isEqualToString:@"@"]) {
        return handler_returning_id(userdata);
    }
    else if ([returnType isEqualToString:@"i"]) {
        return handler_returning_int(userdata);
    }
    else if ([returnType isEqualToString:@"C"]) {
        return handler_returning_bool(userdata);
    }
    else if ([returnType isEqualToString:@"f"]) {
        return handler_returning_float(userdata);
    }
    else if ([returnType isEqualToString:@"d"]) {
        return handler_returning_double(userdata);
    }
    else if ([returnType isEqualToString:@"{CGRect={CGPoint=ff}{CGSize=ff}}"]) {
        return handler_returning_CGRect(userdata);
    }
    else if ([returnType isEqualToString:@"{CGPoint=ff}"]) {
        return handler_returning_CGPoint(userdata);
    }
    else if ([returnType isEqualToString:@"{CGSize=ff}"]) {
        return handler_returning_CGSize(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSRange=II}"]) {
        return handler_returning_NSRange(userdata);
    }
#if !TARGET_OS_IPHONE
    else if ([returnType isEqualToString:@"{_NSRect={_NSPoint=dd}{_NSSize=dd}}"]) {
        return handler_returning_NSRect(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSPoint=dd}"]) {
        return handler_returning_NSPoint(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSSize=dd}"]) {
        return handler_returning_NSSize(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSRange=QQ}"]) {
        return handler_returning_NSRange(userdata);
    }
#endif
    else {
#if TARGET_OS_IPHONE
        // this is only a problem on iOS.
        NSLog(@"UNKNOWN RETURN TYPE %@", returnType);
#endif
    }
    // the following is deprecated. Now that we can create IMPs from blocks, we don't need handler pools.
    if (!handlerWarehouse) {
        return NULL;
    }
    NuHandlers *handlers = [handlerWarehouse objectForKey:returnType];
    if (handlers) {
        if (handlers->_next_free_handler < handlers->_handler_count) {
            handlers->_handlers[handlers->_next_free_handler].description = userdata;
            IMP handler = handlers->_handlers[handlers->_next_free_handler].handler;
            handlers->_next_free_handler++;
            return handler;
        }
    }
    return NULL;
}

@end

#pragma mark - NuMacro_0.m
@interface NuMacro_0 (){
@protected
    NSString *_name;
    NuCell *_body;
	NSMutableSet *_gensyms;
}
@end

@implementation NuMacro_0

+ (id) macroWithName:(NSString *)n body:(NuCell *)b{
    return [[[self alloc] initWithName:n body:b] autorelease];
}

- (void) dealloc{
    [_body release];
    [super dealloc];
}

- (NSString *) name{
    return _name;
}

- (NuCell *) body{
    return _body;
}

- (NSSet *) gensyms{
    return _gensyms;
}

- (void) collectGensyms:(NuCell *)cell{
    id car = [cell car];
    if ([car atom]) {
        if (nu_objectIsKindOfClass(car, [NuSymbol class]) && [car isGensym]) {
            [_gensyms addObject:car];
        }
    }
    else if (car && (car != [NSNull NU_null])) {
        [self collectGensyms:car];
    }
    id cdr = [cell cdr];
    if (cdr && (cdr != [NSNull NU_null])) {
        [self collectGensyms:cdr];
    }
}

- (id) initWithName:(NSString *)n body:(NuCell *)b{
    if ((self = [super init])) {
        _name = [n retain];
        _body = [b retain];
        _gensyms = [[NSMutableSet alloc] init];
        [self collectGensyms:_body];
    }
    return self;
}

- (NSString *) stringValue{
    return [NSString stringWithFormat:@"(macro-0 %@ %@)", _name, [_body stringValue]];
}

- (id) body:(NuCell *) oldBody withGensymPrefix:(NSString *) prefix symbolTable:(NuSymbolTable *) symbolTable{
    NuCell *newBody = [[[NuCell alloc] init] autorelease];
    id car = [oldBody car];
    if (car == [NSNull NU_null]) {
        [newBody setCar:car];
    }
    else if ([car atom]) {
        if (nu_objectIsKindOfClass(car, [NuSymbol class]) && [car isGensym]) {
            [newBody setCar:[symbolTable symbolWithString:[NSString stringWithFormat:@"%@%@", prefix, [car stringValue]]]];
        }
        else if (nu_objectIsKindOfClass(car, [NSString class])) {
            // Here we replace gensyms in interpolated strings.
            // The current solution is workable but fragile;
            // we just blindly replace the gensym names with their expanded names.
            // It would be better to
            // 		1. only replace gensym names in interpolated expressions.
            // 		2. ensure substitutions never overlap.  To do this, I think we should
            //           a. order gensyms by size and do the longest ones first.
            //           b. make the gensym transformation idempotent.
            // That's for another day.
            // For now, I just substitute each gensym name with its expansion.
            //
            NSMutableString *tempString = [NSMutableString stringWithString:car];
            //NSLog(@"checking %@", tempString);
            NSEnumerator *gensymEnumerator = [_gensyms objectEnumerator];
            NuSymbol *gensymSymbol;
            while ((gensymSymbol = [gensymEnumerator nextObject])) {
                //NSLog(@"gensym is %@", [gensymSymbol stringValue]);
                [tempString replaceOccurrencesOfString:[gensymSymbol stringValue]
                                            withString:[NSString stringWithFormat:@"%@%@", prefix, [gensymSymbol stringValue]]
                                               options:0 range:NSMakeRange(0, [tempString length])];
            }
            //NSLog(@"setting string to %@", tempString);
            [newBody setCar:tempString];
        }
        else {
            [newBody setCar:car];
        }
    }
    else {
        [newBody setCar:[self body:car withGensymPrefix:prefix symbolTable:symbolTable]];
    }
    id cdr = [oldBody cdr];
    if (cdr && (cdr != [NSNull NU_null])) {
        [newBody setCdr:[self body:cdr withGensymPrefix:prefix symbolTable:symbolTable]];
    }
    else {
        [newBody setCdr:cdr];
    }
    return newBody;
}

- (id) expandUnquotes:(id) oldBody withContext:(NSMutableDictionary *) context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if (oldBody == [NSNull null])
        return oldBody;
    id unquote = [symbolTable symbolWithString:@"unquote"];
    id car = [oldBody car];
    id cdr = [oldBody cdr];
    if ([car atom]) {
        if (car == unquote) {
            return [[cdr car] evalWithContext:context];
        }
        else {
            NuCell *newBody = [[[NuCell alloc] init] autorelease];
            [newBody setCar:car];
            [newBody setCdr:[self expandUnquotes:cdr withContext:context]];
            return newBody;
        }
    }
    else {
        NuCell *newBody = [[[NuCell alloc] init] autorelease];
        [newBody setCar:[self expandUnquotes:car withContext:context]];
        [newBody setCdr:[self expandUnquotes:cdr withContext:context]];
        return newBody;
    }
}


- (id) expandAndEval:(id)cdr context:(NSMutableDictionary *)calling_context evalFlag:(BOOL)evalFlag{
    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];
    
    // save the current value of margs
    id old_margs = [calling_context objectForKey:[symbolTable symbolWithString:@"margs"]];
    // set the arguments to the special variable "margs"
    [calling_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithString:@"margs"]];
    // evaluate the body of the block in the calling context (implicit progn)
    
    // if the macro contains gensyms, give them a unique prefix
    NSUInteger gensymCount = [[self gensyms] count];
    id gensymPrefix = nil;
    if (gensymCount > 0) {
        gensymPrefix = [NSString stringWithFormat:@"g%ld", [NuMath random]];
    }
    
    id bodyToEvaluate = (gensymCount == 0)
    ? (id)_body : [self body:_body withGensymPrefix:gensymPrefix symbolTable:symbolTable];
    
    // uncomment this to get the old (no gensym) behavior.
    //bodyToEvaluate = body;
    //NSLog(@"evaluating %@", [bodyToEvaluate stringValue]);
    
    id value = [self expandUnquotes:bodyToEvaluate withContext:calling_context];
    
	if (evalFlag)
	{
		id cursor = value;
        
	    while (cursor && (cursor != [NSNull NU_null])) {
	        value = [[cursor car] evalWithContext:calling_context];
	        cursor = [cursor cdr];
	    }
	}
    
    // restore the old value of margs
    if (old_margs == nil) {
        [calling_context removeObjectForKey:[symbolTable symbolWithString:@"margs"]];
    }
    else {
        [calling_context setPossiblyNullObject:old_margs forKey:[symbolTable symbolWithString:@"margs"]];
    }
    
#if 0
    // I would like to remove gensym values and symbols at the end of a macro's execution,
    // but there is a problem with this: the gensym assignments could be used in a closure,
    // and deleting them would cause that to break. See the testIvarAccessorMacro unit
    // test for an example of this. So for now, the code below is disabled.
    //
    // remove the gensyms from the context; this also releases their assigned values
    NSArray *gensymArray = [gensyms allObjects];
    for (int i = 0; i < gensymCount; i++) {
        NuSymbol *gensymBase = [gensymArray objectAtIndex:i];
        NuSymbol *gensymSymbol = [symbolTable symbolWithString:[NSString stringWithFormat:@"%@%@", gensymPrefix, [gensymBase stringValue]]];
        [calling_context removeObjectForKey:gensymSymbol];
        [symbolTable removeSymbol:gensymSymbol];
    }
#endif
    return value;
}


- (id) expand1:(id)cdr context:(NSMutableDictionary*)calling_context{
	return [self expandAndEval:cdr context:calling_context evalFlag:NO];
}


- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context{
	return [self expandAndEval:cdr context:calling_context evalFlag:YES];
}

@end

#pragma mark - NuMacro_1.m

//#define MACRO1_DEBUG	1

// Following  debug output on and off for this file only
#ifdef MACRO1_DEBUG
#define Macro1Debug(arg...) NSLog(arg)
#else
#define Macro1Debug(arg...)
#endif

@interface NuMacro_1 (){
	NuCell *_parameters;
}
@end

@implementation NuMacro_1

+ (id) macroWithName:(NSString *)n parameters:(NuCell*)p body:(NuCell *)b{
    return [[[self alloc] initWithName:n parameters:p body:b] autorelease];
}

- (void) dealloc{
    [_parameters release];
    [super dealloc];
}

- (BOOL) findAtom:(id)atom inSequence:(id)sequence{
    if (atom == nil || atom == [NSNull NU_null])
        return NO;
    
    if (sequence == nil || sequence == [NSNull NU_null])
        return NO;
    
    if ([[atom stringValue] isEqualToString:[sequence stringValue]])
        return YES;
    
    if ([sequence class] == [NuCell class]) {
        return (   [self findAtom:atom inSequence:[sequence car]]
                || [self findAtom:atom inSequence:[sequence cdr]]);
    }
    
    return NO;
}

- (id) initWithName:(NSString *)n parameters:(NuCell *)p body:(NuCell *)b{
    if ((self = [super initWithName:n body:b])) {
        _parameters = [p retain];
        
        if (([_parameters length] == 1)
            && ([[[_parameters car] stringValue] isEqualToString:@"*args"])) {
            // Skip the check
        }
        else {
            BOOL foundArgs = [self findAtom:@"*args" inSequence:_parameters];
            
            if (foundArgs) {
                printf("Warning: Overriding implicit variable '*args'.\n");
            }
        }
    }
    return self;
}

- (NSString *) stringValue{
    return [NSString stringWithFormat:@"(macro %@ %@ %@)", _name, [_parameters stringValue], [_body stringValue]];
}

- (void) dumpContext:(NSMutableDictionary*)context{
#ifdef MACRO1_DEBUG
    NSArray* keys = [context allKeys];
    NSUInteger count = [keys count];
    for (int i = 0; i < count; i++) {
        id key = [keys objectAtIndex:i];
        Macro1Debug(@"contextdump: %@  =  %@  [%@]", key,
                    [[context objectForKey:key] stringValue],
                    [[context objectForKey:key] class]);
    }
#endif
}

- (void) restoreArgs:(id)old_args context:(NSMutableDictionary*)calling_context{
    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];
    
    if (old_args == nil) {
        [calling_context removeObjectForKey:[symbolTable symbolWithString:@"*args"]];
    }
    else {
        [calling_context setPossiblyNullObject:old_args forKey:[symbolTable symbolWithString:@"*args"]];
    }
}

- (void)restoreBindings:(id)bindings
     forMaskedVariables:(NSMutableDictionary*)maskedVariables
            fromContext:(NSMutableDictionary*)calling_context{
    id plist = bindings;
    
    while (plist && (plist != [NSNull NU_null])) {
        id param = [[plist car] car];
        
        Macro1Debug(@"restoring bindings: looking up key: %@",
                    [param stringValue]);
        
        [calling_context removeObjectForKey:param];
        id pvalue = [maskedVariables objectForKey:param];
        
        Macro1Debug(@"restoring calling context for: %@, value: %@",
                    [param stringValue], [pvalue stringValue]);
        
        if (pvalue) {
            [calling_context setPossiblyNullObject:pvalue forKey:param];
        }
        
        plist = [plist cdr];
    }
}

- (id) destructuringListAppend:(id)lhs withList:(id)rhs{
    Macro1Debug(@"Append: lhs = %@  rhs = %@", [lhs stringValue], [rhs stringValue]);
    
    if (lhs == nil || lhs == [NSNull NU_null])
        return rhs;
    
    if (rhs == nil || rhs == [NSNull NU_null])
        return lhs;
    
    id cursor = lhs;
    
    while (   cursor
           && (cursor != [NSNull NU_null])
           && [cursor cdr]
           && ([cursor cdr] != [NSNull NU_null])) {
        cursor = [cursor cdr];
    }
    
    [cursor setCdr:rhs];
    
    Macro1Debug(@"Append: result = %@", [lhs stringValue]);
    
    return lhs;
}

- (id) mdestructure:(id)pattern withSequence:(id)sequence{
    Macro1Debug(@"mdestructure: pat: %@  seq: %@", [pattern stringValue], [sequence stringValue]);
    
	// ((and (not pat) seq)
	if (   ((pattern == nil) || (pattern == [NSNull NU_null]))
	    && !((sequence == [NSNull NU_null]) || (sequence == nil))) {
        [NSException raise:@"NuDestructureException"
                    format:@"Attempt to match empty pattern to non-empty object %@", [self stringValue]];
    }
    // ((not pat) nil)
    else if ((pattern == nil) || (pattern == [NSNull NU_null])) {
        return nil;
    }
    // ((eq pat '_) '())  ; wildcard match produces no binding
    else if ([[pattern stringValue] isEqualToString:@"_"]) {
        return nil;
    }
    // ((symbol? pat)
    //   (let (seq (if (eq ((pat stringValue) characterAtIndex:0) '*')
    //                 (then (list seq))
    //                 (else seq)))
    //        (list (list pat seq))))
    else if ([pattern class] == [NuSymbol class]) {
        id result;
        
        if ([[pattern stringValue] characterAtIndex:0] == '*') {
            // List-ify sequence
            id l = [[[NuCell alloc] init] autorelease];
            [l setCar:sequence];
            result = l;
        }
        else {
            result = sequence;
        }
        
        // (list pattern sequence)
        id p = [[[NuCell alloc] init] autorelease];
        id s = [[[NuCell alloc] init] autorelease];
        
        [p setCar:pattern];
        [p setCdr:s];
        [s setCar:result];
        
        // (list (list pattern sequence))
        id l = [[[NuCell alloc] init] autorelease];
        [l setCar:p];
        
        return l;
    }
    // ((pair? pat)
    //   (if (and (symbol? (car pat))
    //       (eq (((car pat) stringValue) characterAtIndex:0) '*'))
    //       (then (list (list (car pat) seq)))
    //       (else ((let ((bindings1 (mdestructure (car pat) (car seq)))
    //                    (bindings2 (mdestructure (cdr pat) (cdr seq))))
    //                (append bindings1 bindings2))))))
    else if ([pattern class] == [NuCell class]) {
        if (   ([[pattern car] class] == [NuSymbol class])
            && ([[[pattern car] stringValue] characterAtIndex:0] == '*')) {
            
            id l1 = [[[NuCell alloc] init] autorelease];
            id l2 = [[[NuCell alloc] init] autorelease];
            id l3 = [[[NuCell alloc] init] autorelease];
            [l1 setCar:[pattern car]];
            [l1 setCdr:l2];
            [l2 setCar:sequence];
            [l3 setCar:l1];
            
            return l3;
        }
        else {
            if (sequence == nil || sequence == [NSNull NU_null]) {
                [NSException raise:@"NuDestructureException"
                            format:@"Attempt to match non-empty pattern to empty object"];
            }
            
            id b1 = [self mdestructure:[pattern car] withSequence:[sequence car]];
            id b2 = [self mdestructure:[pattern cdr] withSequence:[sequence cdr]];
            
            id newList = [self destructuringListAppend:b1 withList:b2];
            
            Macro1Debug(@"jsb:   dbind: %@", [newList stringValue]);
            return newList;
        }
    }
    // (else (throw* "NuMatchException"
    //               "pattern is not nil, a symbol or a pair: #{pat}"))))
    else {
        [NSException raise:@"NuDestructureException"
                    format:@"Pattern is not nil, a symbol or a pair: %@", [pattern stringValue]];
    }
    
    // Just for aesthetics...
    return nil;
}

- (id) expandAndEval:(id)cdr context:(NSMutableDictionary*)calling_context evalFlag:(BOOL)evalFlag{
    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];
    
    NSMutableDictionary* maskedVariables = [[NSMutableDictionary alloc] init];
    
    id plist;
    
    Macro1Debug(@"Dumping context:");
    Macro1Debug(@"---------------:");
#ifdef MACRO1_DEBUG
    [self dumpContext:calling_context];
#endif
    id old_args = [calling_context objectForKey:[symbolTable symbolWithString:@"*args"]];
    [calling_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithString:@"*args"]];
    
    id destructure;
    
    @try
    {
        // Destructure the arguments
        destructure = [self mdestructure:_parameters withSequence:cdr];
    }
    @catch (id exception) {
        // Destructure failed...restore/remove *args
        [self restoreArgs:old_args context:calling_context];
        
        @throw;
    }
    
    plist = destructure;
    while (plist && (plist != [NSNull NU_null])) {
        id parameter = [[plist car] car];
        id value = [[[plist car] cdr] car];
        Macro1Debug(@"Destructure: %@ = %@", [parameter stringValue], [value stringValue]);
        
        id pvalue = [calling_context objectForKey:parameter];
        
        if (pvalue) {
            Macro1Debug(@"  Saving context: %@ = %@",
                        [parameter stringValue],
                        [pvalue stringValue]);
            [maskedVariables setPossiblyNullObject:pvalue forKey:parameter];
        }
        
        [calling_context setPossiblyNullObject:value forKey:parameter];
        
        plist = [plist cdr];
    }
    
    Macro1Debug(@"Dumping context (after destructure):");
    Macro1Debug(@"-----------------------------------:");
#ifdef MACRO1_DEBUG
    [self dumpContext:calling_context];
#endif
    // evaluate the body of the block in the calling context (implicit progn)
    id value = [NSNull NU_null];
    
    // if the macro contains gensyms, give them a unique prefix
    NSUInteger gensymCount = [[self gensyms] count];
    id gensymPrefix = nil;
    if (gensymCount > 0) {
        gensymPrefix = [NSString stringWithFormat:@"g%ld", [NuMath random]];
    }
    
    id bodyToEvaluate = (gensymCount == 0)
    ? (id)_body : [self body:_body withGensymPrefix:gensymPrefix symbolTable:symbolTable];
    
    // Macro1Debug(@"macro evaluating: %@", [bodyToEvaluate stringValue]);
    // Macro1Debug(@"macro context: %@", [calling_context stringValue]);
    
    @try
    {
        // Macro expansion
        id cursor = [self expandUnquotes:bodyToEvaluate withContext:calling_context];
        while (cursor && (cursor != [NSNull NU_null])) {
            Macro1Debug(@"macro eval cursor: %@", [cursor stringValue]);
            value = [[cursor car] evalWithContext:calling_context];
            Macro1Debug(@"macro expand value: %@", [value stringValue]);
            cursor = [cursor cdr];
        }
        
        // Now that macro expansion is done, restore the masked calling context variables
        [self restoreBindings:destructure
           forMaskedVariables:maskedVariables
                  fromContext:calling_context];
        
        [maskedVariables release];
        maskedVariables = nil;
        
        // Macro evaluation
        // If we're just macro-expanding, don't do this step...
        if (evalFlag) {
            Macro1Debug(@"About to execute: %@", [value stringValue]);
            value = [value evalWithContext:calling_context];
            Macro1Debug(@"macro eval value: %@", [value stringValue]);
        }
        
        Macro1Debug(@"Dumping context at end:");
        Macro1Debug(@"----------------------:");
#ifdef MACRO1_DEBUG
        [self dumpContext:calling_context];
#endif
        // restore the old value of *args
        [self restoreArgs:old_args context:calling_context];
        
        Macro1Debug(@"macro result: %@", value);
    }
    @catch (id exception) {
        if (maskedVariables) {
            Macro1Debug(@"Caught exception in macro, restoring bindings");
            
            [self restoreBindings:destructure
               forMaskedVariables:maskedVariables
                      fromContext:calling_context];
            
            Macro1Debug(@"Caught exception in macro, releasing maskedVariables");
            
            [maskedVariables release];
        }
        
        Macro1Debug(@"Caught exception in macro, restoring masked arguments");
        
        [self restoreArgs:old_args context:calling_context];
        
        Macro1Debug(@"Caught exception in macro, rethrowing...");
        
        @throw;
    }
    
    return value;
}

- (id) expand1:(id)cdr context:(NSMutableDictionary*)calling_context{
    return [self expandAndEval:cdr context:calling_context evalFlag:NO];
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context{
    return [self expandAndEval:cdr context:calling_context evalFlag:YES];
}

@end

#pragma mark - NuMethod.m
@interface NuMethod (){
    Method _m;
}
@end

@implementation NuMethod

- (id) initWithMethod:(Method) method{
    if ((self = [super init])) {
        _m = method;
    }
    return self;
}

- (NSString *) name{
    return (id)_m ? [NSString stringWithCString:(sel_getName(method_getName(_m))) encoding:NSUTF8StringEncoding] : [NSNull NU_null];
}

- (int) argumentCount{
    return method_getNumberOfArguments(_m);
}

- (NSString *) typeEncoding{
    return [NSString stringWithCString:method_getTypeEncoding(_m) encoding:NSUTF8StringEncoding];
}

- (NSString *) signature{
    const char *encoding = method_getTypeEncoding(_m);
    NSInteger len = strlen(encoding)+1;
    char *signature = (char *) malloc (len * sizeof(char));
    method_getReturnType(_m, signature, len);
    NSInteger step = strlen(signature);
    char *start = &signature[step];
    len -= step;
    int argc = method_getNumberOfArguments(_m);
    int i;
    for (i = 0; i < argc; i++) {
        method_getArgumentType(_m, i, start, len);
        step = strlen(start);
        start = &start[step];
        len -= step;
    }
    //  printf("%s %d %d %s\n", sel_getName(method_getName(m)), i, len, signature);
    id result = [NSString stringWithCString:signature encoding:NSUTF8StringEncoding];
    free(signature);
    return result;
}

- (NSString *) argumentType:(int) i{
    if (i >= method_getNumberOfArguments(_m))
        return nil;
    char *argumentType = method_copyArgumentType(_m, i);
    id result = [NSString stringWithCString:argumentType encoding:NSUTF8StringEncoding];
    free(argumentType);
    return result;
}

- (NSString *) returnType{
    char *returnType = method_copyReturnType(_m);
    id result = [NSString stringWithCString:returnType encoding:NSUTF8StringEncoding];
    free(returnType);
    return result;
}

- (NuBlock *) block{
    IMP imp = method_getImplementation(_m);
    NuBlock *block = nil;
    if (nu_block_table) {
        block = [nu_block_table objectForKey:[NSNumber numberWithUnsignedLong:(unsigned long) imp]];
    }
    return block;
}

- (NSComparisonResult) compare:(NuMethod *) anotherMethod{
    return [[self name] compare:[anotherMethod name]];
}

@end

#pragma mark - NuObjCRuntime.m

static IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types){
    if (class_addMethod(cls, name, imp, types)) {
        return imp;
    } else {
        return class_replaceMethod(cls, name, imp, types);
    }
}

static void nu_class_addInstanceVariable_withSignature(Class thisClass, const char *variableName, const char *signature){
    extern size_t size_of_objc_type(const char *typeString);
    size_t size = size_of_objc_type(signature);
    uint8_t alignment = log2(size);
    BOOL result = class_addIvar(thisClass, variableName, size, alignment, signature);
    if (!result) {
        [NSException raise:@"NuAddIvarFailed"
                    format:@"failed to add instance variable %s to class %s", variableName, class_getName(thisClass)];
    }
    //NSLog(@"adding ivar named %s to %s, result is %d", variableName, class_getName(thisClass), result);
}

static BOOL nu_copyInstanceMethod(Class destinationClass, Class sourceClass, SEL selector){
    Method m = class_getInstanceMethod(sourceClass, selector);
    if (!m) {
        return NO;
    }
    IMP imp = method_getImplementation(m);
    if (!imp) {
        return NO;
    }
    const char *signature = method_getTypeEncoding(m);
    if (!signature) {
        return NO;
    }
    BOOL result = (nu_class_replaceMethod(destinationClass, selector, imp, signature) != 0);
    return result;
}

static BOOL nu_objectIsKindOfClass(id object, Class class){
    if (object == NULL) {
        return NO;
    }
    Class classCursor = object_getClass(object);
    while (classCursor) {
        if (classCursor == class) {
            return YES;
        }
        classCursor = class_getSuperclass(classCursor);
    }
    return NO;
}

// This function attempts to recognize the return type from a method signature.
// It scans across the signature until it finds a complete return type string,
// then it inserts a null to mark the end of the string.
static void nu_markEndOfObjCTypeString(char *type, size_t len){
    size_t i;
    char final_char = 0;
    char start_char = 0;
    int depth = 0;
    for (i = 0; i < len; i++) {
        switch(type[i]) {
            case '[':
            case '{':
            case '(':
                // we want to scan forward to a closing character
                if (!final_char) {
                    start_char = type[i];
                    final_char = (start_char == '[') ? ']' : (start_char == '(') ? ')' : '}';
                    depth = 1;
                }
                else if (type[i] == start_char) {
                    depth++;
                }
                break;
            case ']':
            case '}':
            case ')':
                if (type[i] == final_char) {
                    depth--;
                    if (depth == 0) {
                        if (i+1 < len)
                            type[i+1] = 0;
                        return;
                    }
                }
                break;
            case 'b':                             // bitfields
                if (depth == 0) {
                    // scan forward, reading all subsequent digits
                    i++;
                    while ((i < len) && (type[i] >= '0') && (type[i] <= '9'))
                        i++;
                    if (i+1 < len)
                        type[i+1] = 0;
                    return;
                }
            case '^':                             // pointer
            case 'r':                             // const
            case 'n':                             // in
            case 'N':                             // inout
            case 'o':                             // out
            case 'O':                             // bycopy
            case 'R':                             // byref
            case 'V':                             // oneway
                break;                            // keep going, these are all modifiers.
            case 'c': case 'i': case 's': case 'l': case 'q':
            case 'C': case 'I': case 'S': case 'L': case 'Q':
            case 'f': case 'd': case 'B': case 'v': case '*':
            case '@': case '#': case ':': case '?': default:
                if (depth == 0) {
                    if (i+1 < len)
                        type[i+1] = 0;
                    return;
                }
                break;
        }
    }
}
#pragma mark - NuObject.m

@protocol NuCanSetAction
- (void) setAction:(SEL) action;
@end

// use this to look up selectors with symbols
@interface NuSelectorCache : NSObject{
    NuSymbol *_symbol;
    NuSelectorCache *_parent;
    NSMutableDictionary *_children;
    SEL _selector;
}

@end

@implementation NuSelectorCache

+ (NuSelectorCache *) sharedSelectorCache{
    static NuSelectorCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[self alloc] init];
    });
    return sharedCache;
}

- (NuSelectorCache *) init{
    if ((self = [super init])) {
        _symbol = nil;
        _parent = nil;
        _children = [[NSMutableDictionary alloc] init];
        _selector = NULL;
    }
    return self;
}

- (NuSymbol *) symbol {return _symbol;}
- (NuSelectorCache *) parent {return _parent;}
- (NSMutableDictionary *) children {return _children;}

- (SEL) selector{
    return _selector;
}

- (void) setSelector:(SEL) s{
    _selector = s;
}

- (NuSelectorCache *) initWithSymbol:(NuSymbol *)s parent:(NuSelectorCache *)p{
    if ((self = [super init])) {
        _symbol = s;
        _parent = p;
        _children = [[NSMutableDictionary alloc] init];
        _selector = NULL;
    }
    return self;
}

- (NSString *) selectorName{
    NSMutableArray *selectorStrings = [NSMutableArray array];
    [selectorStrings addObject:[[self symbol] stringValue]];
    id p = _parent;
    while ([p symbol]) {
        [selectorStrings addObject:[[p symbol] stringValue]];
        p = [p parent];
    }
    NSUInteger max = [selectorStrings count];
    NSInteger i;
    for (i = 0; i < max/2; i++) {
        [selectorStrings exchangeObjectAtIndex:i withObjectAtIndex:(max - i - 1)];
    }
    return [selectorStrings componentsJoinedByString:@""];
}

- (NuSelectorCache *) lookupSymbol:(NuSymbol *)childSymbol{
    NuSelectorCache *child = [_children objectForKey:childSymbol];
    if (!child) {
        child = [[[NuSelectorCache alloc] initWithSymbol:childSymbol parent:self] autorelease];
        NSString *selectorString = [child selectorName];
        [child setSelector:sel_registerName([selectorString cStringUsingEncoding:NSUTF8StringEncoding])];
        [_children setValue:child forKey:(id)childSymbol];
    }
    return child;
}

@end

@implementation NSObject(Nu)
- (bool) atom{
    return true;
}

- (id) evalWithContext:(NSMutableDictionary *) context{
    return self;
}

- (NSString *) stringValue{
    return [NSString stringWithFormat:@"<%s:%lx>", class_getName(object_getClass(self)), (long) self];
}

- (id) car{
    [NSException raise:@"NuCarCalledOnAtom"
                format:@"car called on atom for object %@",
     self];
    return [NSNull NU_null];
}

- (id) cdr{
    [NSException raise:@"NuCdrCalledOnAtom"
                format:@"cdr called on atom for object %@",
     self];
    return [NSNull NU_null];
}


- (id) sendMessage:(id)cdr withContext:(NSMutableDictionary *)context{
    // By themselves, Objective-C objects evaluate to themselves.
    if (!cdr || (cdr == [NSNull NU_null]))
        return self;
    
    // But when they're at the head of a list, that list is converted into a message that is sent to the object.
    id result = nil;
    @autoreleasepool {
        // Collect the method selector and arguments.
        // This seems like a bottleneck, and it also lacks flexibility.
        // Replacing explicit string building with the selector cache reduced runtimes by around 20%.
        // Methods with variadic arguments (NSArray arrayWithObjects:...) are not supported.
        NSMutableArray *args = [[NSMutableArray alloc] init];
        id cursor = cdr;
        SEL sel = 0;
        id nextSymbol = [cursor car];
        if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class])) {
            // The commented out code below was the original approach.
            // methods were identified by concatenating symbols and looking up the resulting method -- on every method call
            // that was slow but simple
            // NSMutableString *selectorString = [NSMutableString stringWithString:[nextSymbol stringValue]];
            NuSelectorCache *selectorCache = [[NuSelectorCache sharedSelectorCache] lookupSymbol:nextSymbol];
            cursor = [cursor cdr];
            while (cursor && (cursor != [NSNull NU_null])) {
                [args addObject:[cursor car]];
                cursor = [cursor cdr];
                if (cursor && (cursor != [NSNull NU_null])) {
                    id nextSymbol = [cursor car];
                    if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class]) && [nextSymbol isLabel]) {
                        // [selectorString appendString:[nextSymbol stringValue]];
                        selectorCache = [selectorCache lookupSymbol:nextSymbol];
                    }
                    cursor = [cursor cdr];
                }
            }
            // sel = sel_getUid([selectorString cStringUsingEncoding:NSUTF8StringEncoding]);
            sel = [selectorCache selector];
        }
        
        id target = self;
        
        // Look up the appropriate method to call for the specified selector.
        Method m;
        // instead of isMemberOfClass:, which may be blocked by an NSProtocolChecker
        BOOL isAClass = (object_getClass(self) == [NuClass class]);
        if (isAClass) {
            // Class wrappers (objects of type NuClass) get special treatment. Instance methods are sent directly to the class wrapper object.
            // But when a class method is sent to a class wrapper, the method is instead sent as a class method to the wrapped class.
            // This makes it possible to call class methods from Nu, but there is no way to directly call class methods of NuClass from Nu.
            id wrappedClass = [((NuClass *) self) wrappedClass];
            m = class_getClassMethod(wrappedClass, sel);
            if (m)
                target = wrappedClass;
            else
                m = class_getInstanceMethod(object_getClass(self), sel);
        }
        else {
            m = class_getInstanceMethod(object_getClass(self), sel);
            if (!m) m = class_getClassMethod(object_getClass(self), sel);
        }
        result = [NSNull NU_null];
        if (m) {
            // We have a method that matches the selector.
            // First, evaluate the arguments.
            NSMutableArray *argValues = [[NSMutableArray alloc] init];
            NSUInteger i;
            NSUInteger imax = [args count];
            for (i = 0; i < imax; i++) {
                [argValues addObject:[[args objectAtIndex:i] evalWithContext:context]];
            }
            // Then call the method.
            result = nu_calling_objc_method_handler(target, m, argValues);
            [argValues release];
        }
        else {
            // If the head of the list is a label, we treat the list as a property list.
            // We just evaluate the elements of the list and return the result.
            if (nu_objectIsKindOfClass(self, [NuSymbol class]) && [((NuSymbol *)self) isLabel]) {
                NuCell *cell = [[[NuCell alloc] init] autorelease];
                [cell setCar: self];
                id cursor = cdr;
                id result_cursor = cell;
                while (cursor && (cursor != [NSNull NU_null])) {
                    id arg = [[cursor car] evalWithContext:context];
                    [result_cursor setCdr:[[[NuCell alloc] init] autorelease]];
                    result_cursor = [result_cursor cdr];
                    [result_cursor setCar:arg];
                    cursor = [cursor cdr];
                }
                result = cell;
            }
            // Messaging null is ok.
            else if (self == [NSNull NU_null]) {
            }
            // Test if target specifies another object that should receive the message
            else if ( (target = [target forwardingTargetForSelector:sel]) ) {
                //NSLog(@"found forwarding target: %@ for selector: %@", target, NSStringFromSelector(sel));
                result = [target sendMessage:cdr withContext:context];
            }
            // Otherwise, call the overridable handler for unknown messages.
            else {
                //NSLog(@"calling handle unknown message for %@", [cdr stringValue]);
                result = [self handleUnknownMessage:cdr withContext:context];
                //NSLog(@"result is %@", result);
            }
        }
        
        [args release];
        [result retain];
    }
    
    [result autorelease];
    return result;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [self sendMessage:cdr withContext:context];
}

+ (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context{
    [NSException raise:@"NuUnknownMessage"
                format:@"unable to find message handler for %@",
     [cdr stringValue]];
    return [NSNull NU_null];
}


- (id) handleUnknownMessage:(id) message withContext:(NSMutableDictionary *) context{
    // Collect the method selector and arguments.
    // This seems like a bottleneck, and it also lacks flexibility.
    // Replacing explicit string building with the selector cache reduced runtimes by around 20%.
    // Methods with variadic arguments (NSArray arrayWithObjects:...) are not supported.
    NSMutableArray *args = [NSMutableArray array];
    id cursor = message;
    SEL sel = 0;
    id nextSymbol = [cursor car];
    if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class])) {
        // The commented out code below was the original approach.
        // methods were identified by concatenating symbols and looking up the resulting method -- on every method call
        // that was slow but simple
        // NSMutableString *selectorString = [NSMutableString stringWithString:[nextSymbol stringValue]];
        NuSelectorCache *selectorCache = [[NuSelectorCache sharedSelectorCache] lookupSymbol:nextSymbol];
        cursor = [cursor cdr];
        while (cursor && (cursor != [NSNull NU_null])) {
            [args addObject:[cursor car]];
            cursor = [cursor cdr];
            if (cursor && (cursor != [NSNull NU_null])) {
                id nextSymbol = [cursor car];
                if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class]) && [nextSymbol isLabel]) {
                    // [selectorString appendString:[nextSymbol stringValue]];
                    selectorCache = [selectorCache lookupSymbol:nextSymbol];
                }
                cursor = [cursor cdr];
            }
        }
        // sel = sel_getUid([selectorString cStringUsingEncoding:NSUTF8StringEncoding]);
        sel = [selectorCache selector];
    }
    
    // If the object responds to methodSignatureForSelector:, we should create and forward an invocation to it.
    NSMethodSignature *methodSignature = sel ? [self methodSignatureForSelector:sel] : 0;
    if (methodSignature) {
        id result = [NSNull null];
        // Create an invocation to forward.
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:self];
        [invocation setSelector:sel];
        // Set any arguments to the invocation.
        NSUInteger i;
        NSUInteger imax = [args count];
        for (i = 0; i < imax; i++) {
            const char *argument_type = [methodSignature getArgumentTypeAtIndex:i+2];
            char *buffer = value_buffer_for_objc_type(argument_type);
            set_objc_value_from_nu_value(buffer, [[args objectAtIndex:i] evalWithContext:context], argument_type);
            [invocation setArgument:buffer atIndex:i+2];
            free(buffer);
        }
        // Forward the invocation.
        [self forwardInvocation:invocation];
        // Get the return value from the invocation.
        NSUInteger length = [[invocation methodSignature] methodReturnLength];
        if (length > 0) {
            char *buffer = (void *)malloc(length);
            [invocation getReturnValue:buffer];
            result = get_nu_value_from_objc_value(buffer, [methodSignature methodReturnType]);
            free(buffer);
        }
        return result;
    }
    
#define AUTOMATIC_IVAR_ACCESSORS
#ifdef AUTOMATIC_IVAR_ACCESSORS
    //NSLog(@"attempting to access ivar %@", [message stringValue]);
    NSInteger message_length = [message length];
    if (message_length == 1) {
        // try to automatically get an ivar
        NSString *ivarName = [[message car] stringValue];
        if ([self hasValueForIvar:ivarName]) {
            id result = [self valueForIvar:ivarName];
            return result;
        }
    }
    else if (message_length == 2) {
        // try to automatically set an ivar
        if ([[[[message car] stringValue] substringWithRange:NSMakeRange(0,3)] isEqualToString:@"set"]) {
            @try
            {
                id firstArgument = [[message car] stringValue];
                id variableName0 = [[firstArgument substringWithRange:NSMakeRange(3,1)] lowercaseString];
                id variableName1 = [firstArgument substringWithRange:NSMakeRange(4, [firstArgument length] - 5)];
                [self setValue:[[[message cdr] car] evalWithContext:context]
                       forIvar:[NSString stringWithFormat:@"%@%@", variableName0, variableName1]];
                return [NSNull NU_null];
            }
            @catch (id error) {
                // NSLog(@"skipping this error: %@", [error description]);
                // no ivar, keep going
            }
        }
    }
#endif
    NuCell *cell = [[[NuCell alloc] init] autorelease];
    [cell setCar:self];
    [cell setCdr:message];
    [NSException raise:@"NuUnknownMessage"
                format:@"unable to find message handler for %@",
     [cell stringValue]];
    return [NSNull NU_null];
}

- (id) valueForIvar:(NSString *) name{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        NSMutableDictionary *sparseIvars = [self associatedObjectForKey:@"__nuivars"];
        if (sparseIvars) {
            // NSLog(@"sparse %@", [sparseIvars description]);
            id result = [sparseIvars objectForKey:name];
            if (result) {
                return result;
            } else {
                return [NSNull NU_null];
            }
        }
        return [NSNull NU_null];
    }
    void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    id result = get_nu_value_from_objc_value(location, ivar_getTypeEncoding(v));
    return result;
}

- (BOOL) hasValueForIvar:(NSString *) name{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        NSMutableDictionary *sparseIvars = [self associatedObjectForKey:@"__nuivars"];
        if (sparseIvars) {
            // NSLog(@"sparse %@", [sparseIvars description]);
            id result = [sparseIvars objectForKey:name];
            if (result) {
                return YES;
            } else {
                return NO;
            }
        }
        return NO;
    }
    //void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    //id result = get_nu_value_from_objc_value(location, ivar_getTypeEncoding(v));
    return YES;
}


- (void) setValue:(id) value forIvar:(NSString *)name{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        NSMutableDictionary *sparseIvars = [self associatedObjectForKey:@"__nuivars"];
        if (!sparseIvars) {
            sparseIvars = [[[NSMutableDictionary alloc] init] autorelease];
            [self setRetainedAssociatedObject:sparseIvars forKey:@"__nuivars"];
        }
        [self willChangeValueForKey:name];
        [sparseIvars setPossiblyNullObject:value forKey:name];
        [self didChangeValueForKey:name];
        return;
    }
    [self willChangeValueForKey:name];
    void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    const char *encoding = ivar_getTypeEncoding(v);
    if (encoding && (strlen(encoding) > 0) && (encoding[0] == '@')) {
        [value retain];
        [*((id *)location) release];
    }
    set_objc_value_from_nu_value(location, value, ivar_getTypeEncoding(v));
    [self didChangeValueForKey:name];
}

+ (NSArray *) classMethods{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self class]), &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) instanceMethods{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList([self class], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) classMethodNames{
    Class c = [self class];
    id methods = [c classMethods];
    return [methods mapSelector:@selector(name)];
    //    return [[c classMethods] mapSelector:@selector(name)];
}

+ (NSArray *) instanceMethodNames{
    Class c = [self class];
    id methods = [c instanceMethods];
    return [methods mapSelector:@selector(name)];
    //    return [[c instanceMethods] mapSelector:@selector(name)];
}

+ (NSArray *) instanceVariableNames{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int ivar_count;
    Ivar *ivar_list = class_copyIvarList([self class], &ivar_count);
    int i;
    for (i = 0; i < ivar_count; i++) {
        [array addObject:[NSString stringWithCString:ivar_getName(ivar_list[i]) encoding:NSUTF8StringEncoding]];
    }
    free(ivar_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSString *) signatureForIvar:(NSString *)name{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    return [NSString stringWithCString:ivar_getTypeEncoding(v) encoding:NSUTF8StringEncoding];
}

+ (id) inheritedByClass:(NuClass *) newClass{
    return nil;
}

+ (id) createSubclassNamed:(NSString *) subclassName{
    Class c = [self class];
    const char *name = [subclassName cStringUsingEncoding:NSUTF8StringEncoding];
    
    // does the class already exist?
    Class s = objc_getClass(name);
    if (s) {
        // the subclass's superclass must be the current class!
        if (c != [s superclass]) {
            NSLog(@"Warning: Class %s already exists and is not a subclass of %s", name, class_getName(c));
        }
    }
    else {
        s = objc_allocateClassPair(c, name, 0);
        objc_registerClassPair(s);
    }
    NuClass *newClass = [[[NuClass alloc] initWithClass:s] autorelease];
    
    if ([self respondsToSelector:@selector(inheritedByClass:)]) {
        [self inheritedByClass:newClass];
    }
    
    return newClass;
}

/*
 + (id) addInstanceMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block
 {
 Class c = [self class];
 return add_method_to_class(c, methodName, signature, block);
 }
 
 + (id) addClassMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block
 {
 Class c = [self class]->isa;
 return add_method_to_class(c, methodName, signature, block);
 }
 */
+ (BOOL) copyInstanceMethod:(NSString *) methodName fromClass:(NuClass *)prototypeClass{
    Class thisClass = [self class];
    Class otherClass = [prototypeClass wrappedClass];
    const char *method_name_str = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    SEL selector = sel_registerName(method_name_str);
    BOOL result = nu_copyInstanceMethod(thisClass, otherClass, selector);
    return result;
}

+ (BOOL) include:(NuClass *)prototypeClass{
    NSArray *methods = [prototypeClass instanceMethods];
    NSEnumerator *enumerator = [methods objectEnumerator];
    id method;
    while ((method = [enumerator nextObject])) {
        // NSLog(@"copying method %@", [method name]);
        [self copyInstanceMethod:[method name] fromClass:prototypeClass];
    }
    return true;
}

+ (NSString *) help{
    return [NSString stringWithFormat:@"This is a class named %s.", class_getName([self class])];
}

- (NSString *) help{
    return [NSString stringWithFormat:@"This is an instance of %s.", class_getName([self class])];
}

// adapted from the CocoaDev MethodSwizzling page

+ (BOOL) exchangeInstanceMethod:(SEL)sel1 withMethod:(SEL)sel2{
    Class myClass = [self class];
    Method method1 = NULL, method2 = NULL;
    
    // First, look for the methods
    method1 = class_getInstanceMethod(myClass, sel1);
    method2 = class_getInstanceMethod(myClass, sel2);
    // If both are found, swizzle them
    if ((method1 != NULL) && (method2 != NULL)) {
        method_exchangeImplementations(method1, method2);
        return true;
    }
    else {
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        return false;
    }
    
    return YES;
}

+ (BOOL) exchangeClassMethod:(SEL)sel1 withMethod:(SEL)sel2{
    Class myClass = [self class];
    Method method1 = NULL, method2 = NULL;
    
    // First, look for the methods
    method1 = class_getClassMethod(myClass, sel1);
    method2 = class_getClassMethod(myClass, sel2);
    
    // If both are found, swizzle them
    if ((method1 != NULL) && (method2 != NULL)) {
        method_exchangeImplementations(method1, method2);
        return true;
    }
    else {
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        return false;
    }
    
    return YES;
}

// Concisely set key-value pairs from a property list.

- (id) set:(NuCell *) propertyList{
    id cursor = propertyList;
    while (cursor && (cursor != [NSNull NU_null]) && ([cursor cdr]) && ([cursor cdr] != [NSNull NU_null])) {
        id key = [cursor car];
        id value = [[cursor cdr] car];
        id label = ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) ? [key labelName] : key;
        if ([label isEqualToString:@"action"] && [self respondsToSelector:@selector(setAction:)]) {
            SEL selector = sel_registerName([value cStringUsingEncoding:NSUTF8StringEncoding]);
            [(id<NuCanSetAction>) self setAction:selector];
        }
        else {
            [self setValue:value forKey:label];
        }
        cursor = [[cursor cdr] cdr];
    }
    return self;
}

- (void) setRetainedAssociatedObject:(id) object forKey:(id) key {
    if ([key isKindOfClass:[NSString class]])
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_RETAIN);
}

- (void) setAssignedAssociatedObject:(id) object forKey:(id) key {
    if ([key isKindOfClass:[NSString class]])
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_ASSIGN);
}

- (void) setCopiedAssociatedObject:(id) object forKey:(id) key {
    if ([key isKindOfClass:[NSString class]])
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_COPY);
}

- (id) associatedObjectForKey:(id) key {
    if ([key isKindOfClass:[NSString class]])
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    return objc_getAssociatedObject(self, key);
}

- (void) removeAssociatedObjects {
    objc_removeAssociatedObjects(self);
}

// Helper. Included because it's so useful.
- (NSData *) XMLPropertyListRepresentation {
    return [NSPropertyListSerialization dataWithPropertyList:self
                                                      format: NSPropertyListXMLFormat_v1_0
                                                     options:0
                                                       error:nil];
}

// Helper. Included because it's so useful.
- (NSData *) binaryPropertyListRepresentation {
    return [NSPropertyListSerialization dataWithPropertyList:self
                                                      format: NSPropertyListBinaryFormat_v1_0
                                                     options:0
                                                       error:nil];
}

@end

#pragma mark - NuOperator.m

@implementation NuBreakException
- (id) init{
    return [super initWithName:@"NuBreakException" reason:@"A break operator was evaluated" userInfo:nil];
}

@end

@implementation NuContinueException
- (id) init{
    return [super initWithName:@"NuContinueException" reason:@"A continue operator was evaluated" userInfo:nil];
}

@end

@implementation NuReturnException
- (id) initWithValue:(id) v{
    if ((self = [super initWithName:@"NuReturnException" reason:@"A return operator was evaluated" userInfo:nil])) {
        _value = [v retain];
        _blockForReturn = nil;
    }
    return self;
}

- (id) initWithValue:(id) v blockForReturn:(id) b{
    if ((self = [super initWithName:@"NuReturnException" reason:@"A return operator was evaluated" userInfo:nil])) {
        _value = [v retain];
        _blockForReturn = b;                           // weak reference
    }
    return self;
}

- (void) dealloc{
    [_value release];
    [super dealloc];
}

- (id) value{
    return _value;
}

- (id) blockForReturn{
    return _blockForReturn;
}

@end

@implementation NuOperator : NSObject
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context {return nil;}
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context {return [self callWithArguments:cdr context:context];}
@end

@interface Nu_car_operator : NuOperator
@end

@implementation Nu_car_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return ([value respondsToSelector:@selector(car)]) ? [value car] : [NSNull NU_null];
}

@end

@interface Nu_cdr_operator : NuOperator
@end

@implementation Nu_cdr_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return ([value respondsToSelector:@selector(cdr)]) ? [value cdr] : [NSNull NU_null];
}

@end

@interface Nu_atom_operator : NuOperator
@end

@implementation Nu_atom_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return [value atom]? [context NU_true]: [context NU_false];
}

@end

@interface Nu_defined_operator : NuOperator
@end

@implementation Nu_defined_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    bool is_defined = YES;
    id cadr = [cdr car];
    @try
    {
        [cadr evalWithContext:context];
    }
    @catch (id exception) {
        // is this an undefined symbol exception? if not, throw it
        if ([[exception name] isEqualToString:@"NuUndefinedSymbol"]) {
            is_defined = NO;
        }
        else {
            @throw(exception);
        }
    }
    return is_defined? [context NU_true]: [NSNull NU_null];
}

@end

@interface Nu_eq_operator : NuOperator
@end

@implementation Nu_eq_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr allChainedPairs:^BOOL(id value1, id value2) {
        return [value1 isEqual:value2];
    } context:context];
}

@end

@interface Nu_neq_operator : NuOperator
@end

@implementation Nu_neq_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr eitherChainedPairs:^BOOL(id value1, id value2) {
        return ![value1 isEqual:value2];
    } context:context];
}

@end

@interface Nu_cons_operator : NuOperator
@end

@implementation Nu_cons_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id cadr = [cdr car];
    id cddr = [cdr cdr];
    id value1 = [cadr evalWithContext:context];
    id value2 = [cddr evalWithContext:context];
    id newCell = [[[NuCell alloc] init] autorelease];
    [newCell setCar:value1];
    [newCell setCdr:value2];
    return newCell;
}

@end

@interface Nu_append_operator : NuOperator
@end

@implementation Nu_append_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id newList = [NSNull NU_null];
    id cursor = nil;
    
    for (id list_to_append in [cdr cellEnumerator]) {
        id item_to_append = [[list_to_append car] evalWithContext:context];
        
        while (item_to_append && (item_to_append != [NSNull NU_null])) {
            if (newList == [NSNull NU_null]) {
                newList = [[[NuCell alloc] init] autorelease];
                cursor = newList;
            }
            else {
                [cursor setCdr: [[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
            }
            id item = [item_to_append car];
            [cursor setCar: item];
            item_to_append = [item_to_append cdr];
        }
    }
    return newList;
}

@end


@interface Nu_apply_operator : NuOperator
@end

@implementation Nu_apply_operator
- (id) prependCell:(id)item withSymbol:(id)symbol{
    id qitem = [[[NuCell alloc] init] autorelease];
    [qitem setCar:symbol];
    [qitem setCdr:[[[NuCell alloc] init] autorelease]];
    [[qitem cdr] setCar:item];
    return qitem;
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id quoteSymbol = [symbolTable symbolWithString:@"quote"];
    
    id fn = [cdr car];
    
    // Arguments to fn can be anything, but last item must be a list
    id qargs = [NSNull NU_null];
    id qargs_cursor = [NSNull NU_null];
    id cursor = [cdr cdr];
    
    while (cursor && (cursor != [NSNull NU_null]) && [cursor cdr] && ([cursor cdr] != [NSNull NU_null])) {
        if (qargs == [NSNull NU_null]) {
            qargs = [[[NuCell alloc] init] autorelease];
            qargs_cursor = qargs;
        }
        else {
            [qargs_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            qargs_cursor = [qargs_cursor cdr];
        }
        
        id item = [[cursor car] evalWithContext:context];
        id qitem = [self prependCell:item withSymbol:quoteSymbol];
        [qargs_cursor setCar:qitem];
        cursor = [cursor cdr];
    }
    
    // The rest of the arguments are in a list
    id args = [cursor evalWithContext:context];
    cursor = args;
    
    while (cursor && (cursor != [NSNull NU_null])) {
        if (qargs == [NSNull NU_null]) {
            qargs = [[[NuCell alloc] init] autorelease];
            qargs_cursor = qargs;
        }
        else {
            [qargs_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            qargs_cursor = [qargs_cursor cdr];
        }
        id item = [cursor car];
        
        id qitem = [self prependCell:item withSymbol:quoteSymbol];
        [qargs_cursor setCar:qitem];
        cursor = [cursor cdr];
    }
    
    // Call the real function with the evaluated and quoted args
    id expr = [[[NuCell alloc] init] autorelease];
    [expr setCar:fn];
    [expr setCdr:qargs];
    
    id result = [expr evalWithContext:context];
    
    return result;
}
@end

@interface Nu_cond_operator : NuOperator
@end

@implementation Nu_cond_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id value = [NSNull NU_null];
    for (id pairs in [cdr cellEnumerator]) {
        id condition = [[pairs car] car];
        id test = [condition evalWithContext:context];
        if (nu_valueIsTrue(test)) {
            return [[[pairs car] cdr] evalAsPrognInContext:context] ?: test;
        }
    }
    return value;
}

@end

@interface Nu_case_operator : NuOperator
@end

@implementation Nu_case_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id target = [[cdr car] evalWithContext:context];
    id cases = [cdr cdr];
    while ([cases cdr] != [NSNull NU_null]) {
        id condition = [[cases car] car];
        id result = [condition evalWithContext:context];
        if ([result isEqual:target]) {
            return [[[cases car] cdr] evalAsPrognInContext:context];
        }
        cases = [cases cdr];
    }
    // or return the last one
    return [[[cases car] cdr] evalAsPrognInContext:context];
}

@end

@interface Nu_if_operator : NuOperator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context flipped:(bool)flip;
@end

@implementation Nu_if_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [self callWithArguments:cdr context:context flipped:NO];
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context flipped:(bool)flip{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    //id thenSymbol = [symbolTable symbolWithString:@"then"];
    id elseSymbol = [symbolTable symbolWithString:@"else"];
    //id elseifSymbol = [symbolTable symbolWithString:@"elseif"];
    
    id result = [NSNull NU_null];
    id test = [[cdr car] evalWithContext:context];
    
    bool testIsTrue = flip ^ nu_valueIsTrue(test);
    bool noneIsTrue = !testIsTrue;
    
    id expressions = [cdr cdr];
    while (expressions && (expressions != [NSNull NU_null])) {
        id nextExpression = [expressions car];
        if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
            /*if ([nextExpression car] == elseifSymbol) {
             test = [[[[expressions car] cdr] car] evalWithContext:context];
             testIsTrue = noneIsTrue && nu_valueIsTrue(test);
             noneIsTrue = noneIsTrue && !testIsTrue;
             if (testIsTrue)
             // skip the test:
             result = [[[nextExpression cdr] cdr] evalWithContext:context];
             }
             else */
            if ([nextExpression car] == elseSymbol) {
                if (noneIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
            else {
                if (testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
        }
        else {
            /*if (nextExpression == elseifSymbol) {
             test = [[[expressions cdr] car] evalWithContext:context];
             testIsTrue = noneIsTrue && nu_valueIsTrue(test);
             noneIsTrue = noneIsTrue && !testIsTrue;
             expressions = [expressions cdr];            // skip the test
             }
             else */
            if (nextExpression == elseSymbol) {
                testIsTrue = noneIsTrue;
                noneIsTrue = NO;
            }
            else {
                if (testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
        }
        expressions = [expressions cdr];
    }
    return result;
}

@end

@interface Nu_unless_operator : Nu_if_operator
@end

@implementation Nu_unless_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [super callWithArguments:cdr context:context flipped:YES];
}

@end

@interface Nu_while_operator : NuOperator
@end

@implementation Nu_while_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id result = [NSNull NU_null];
    id test = [[cdr car] evalWithContext:context];
    while (nu_valueIsTrue(test)) {
        @try
        {
            id expressions = [cdr cdr];
            result = [expressions evalAsPrognInContext:context];
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
        test = [[cdr car] evalWithContext:context];
    }
    return result;
}

@end

@interface Nu_until_operator : NuOperator
@end

@implementation Nu_until_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id result = [NSNull NU_null];
    id test = [[cdr car] evalWithContext:context];
    while (!nu_valueIsTrue(test)) {
        @try
        {
            id expressions = [cdr cdr];
            result = [expressions evalAsPrognInContext:context];
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
        test = [[cdr car] evalWithContext:context];
    }
    return result;
}

@end

@interface Nu_for_operator : NuOperator
@end

@implementation Nu_for_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id result = [NSNull NU_null];
    id controls = [cdr car];                      // this could use some error checking!
    id loopinit = [controls car];
    id looptest = [[controls cdr] car];
    id loopincr = [[[controls cdr] cdr] car];
    // initialize the loop
    [loopinit evalWithContext:context];
    // evaluate the loop condition
    id test = [looptest evalWithContext:context];
    while (nu_valueIsTrue(test)) {
        @try
        {
            id expressions = [cdr cdr];
            result = [expressions evalAsPrognInContext:context];
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
        // perform the end of loop increment step
        [loopincr evalWithContext:context];
        // evaluate the loop condition
        test = [looptest evalWithContext:context];
    }
    return result;
}

@end

@interface Nu_try_operator : NuOperator
@end

@implementation Nu_try_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id catchSymbol = [symbolTable symbolWithString:@"catch"];
    id finallySymbol = [symbolTable symbolWithString:@"finally"];
    id result = [NSNull NU_null];
    
    @try
    {
        // evaluate all the expressions that are outside catch and finally blocks
        id expressions = cdr;
        while (expressions && (expressions != [NSNull NU_null])) {
            id nextExpression = [expressions car];
            if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
                if (([nextExpression car] != catchSymbol) && ([nextExpression car] != finallySymbol)) {
                    result = [nextExpression evalWithContext:context];
                }
            }
            else {
                result = [nextExpression evalWithContext:context];
            }
            expressions = [expressions cdr];
        }
    }
    @catch (id thrownObject) {
        // evaluate all the expressions that are in catch blocks
        id expressions = cdr;
        while (expressions && (expressions != [NSNull NU_null])) {
            id nextExpression = [expressions car];
            if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
                if (([nextExpression car] == catchSymbol)) {
                    // this is a catch block.
                    // the first expression should be a list with a single symbol
                    // that's a name.  we'll set that name to the thing we caught
                    id nameList = [[nextExpression cdr] car];
                    id name = [nameList car];
                    [context setValue:thrownObject forKey:name];
                    // now we loop over the rest of the expressions and evaluate them one by one
                    id cursor = [[nextExpression cdr] cdr];
                    while (cursor && (cursor != [NSNull NU_null])) {
                        result = [[cursor car] evalWithContext:context];
                        cursor = [cursor cdr];
                    }
                }
            }
            expressions = [expressions cdr];
        }
    }
    @finally
    {
        // evaluate all the expressions that are in finally blocks
        id expressions = cdr;
        while (expressions && (expressions != [NSNull NU_null])) {
            id nextExpression = [expressions car];
            if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
                if (([nextExpression car] == finallySymbol)) {
                    // this is a finally block
                    // loop over the rest of the expressions and evaluate them one by one
                    id cursor = [nextExpression cdr];
                    while (cursor && (cursor != [NSNull NU_null])) {
                        result = [[cursor car] evalWithContext:context];
                        cursor = [cursor cdr];
                    }
                }
            }
            expressions = [expressions cdr];
        }
    }
    return result;
}

@end

@interface Nu_throw_operator : NuOperator
@end

@implementation Nu_throw_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id exception = [[cdr car] evalWithContext:context];
    @throw exception;
    return exception;
}

@end

@interface Nu_synchronized_operator : NuOperator
@end

@implementation Nu_synchronized_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    //  NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    
    id object = [[cdr car] evalWithContext:context];
    id result = [NSNull NU_null];
    
    @synchronized(object) {
        // evaluate the rest of the expressions
        id expressions = [cdr cdr];
        while (expressions && (expressions != [NSNull NU_null])) {
            id nextExpression = [expressions car];
            result = [nextExpression evalWithContext:context];
            expressions = [expressions cdr];
        }
    }
    return result;
}

@end

@interface Nu_quote_operator : NuOperator
@end

@implementation Nu_quote_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id cadr = [cdr car];
    return cadr;
}

@end

@interface Nu_quasiquote_eval_operator : NuOperator
@end

@implementation Nu_quasiquote_eval_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    // bqcomma is handled by Nu_quasiquote_operator.
    // If we get here, it means someone called bq_comma
    // outside of a backquote
    [NSException raise:@"NuQuasiquoteEvalOutsideQuasiquote"
                format:@"Comma must be inside a backquote"];
    
    // Purely cosmetic...
    return [NSNull NU_null];
}

@end

@interface Nu_quasiquote_splice_operator : NuOperator
@end

@implementation Nu_quasiquote_splice_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    // bqcomma-at is handled by Nu_quasiquote_operator.
    // If we get here, it means someone called bq_comma
    // outside of a backquote
    [NSException raise:@"NuQuasiquoteSpliceOutsideQuasiquote"
                format:@"Comma-at must be inside a backquote"];
    
    // Purely cosmetic...
    return [NSNull NU_null];
}

@end

// Temporary use for debugging quasiquote functions...
#if 0
#define QuasiLog(args...)   NSLog(args)
#else
#define QuasiLog(args...)
#endif

@interface Nu_quasiquote_operator : NuOperator
@end

@implementation Nu_quasiquote_operator

- (id) evalQuasiquote:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    
    id quasiquote_eval = [[symbolTable symbolWithString:@"quasiquote-eval"] value];
    id quasiquote_splice = [[symbolTable symbolWithString:@"quasiquote-splice"] value];
    
    QuasiLog(@"bq:Entered. callWithArguments cdr = %@", [cdr stringValue]);
    
    id result = [NSNull NU_null];
    id result_cursor = [NSNull NU_null];
    id cursor = cdr;
    
    while (cursor && (cursor != [NSNull NU_null])) {
        id value;
        QuasiLog(@"quasiquote: [cursor car] == %@", [[cursor car] stringValue]);
        
        if ([[cursor car] atom]) {
            // Treat it as a quoted value
            QuasiLog(@"quasiquote: Quoting cursor car: %@", [[cursor car] stringValue]);
            value = [cursor car];
        }
        else if ([cursor car] == [NSNull NU_null]) {
            QuasiLog(@"  quasiquote: null-list");
            value = [NSNull NU_null];
        }
        else if ([[symbolTable lookup:[[[cursor car] car] stringValue]] value] == quasiquote_eval) {
            QuasiLog(@"quasiquote-eval: Evaling: [[cursor car] cdr]: %@", [[[cursor car] cdr] stringValue]);
            value = [[[cursor car] cdr] evalWithContext:context];
            QuasiLog(@"  quasiquote-eval: Value: %@", [value stringValue]);
        }
        else if ([[symbolTable lookup:[[[cursor car] car] stringValue]] value] == quasiquote_splice) {
            QuasiLog(@"quasiquote-splice: Evaling: [[cursor car] cdr]: %@",
                     [[[cursor car] cdr] stringValue]);
            value = [[[cursor car] cdr] evalWithContext:context];
            QuasiLog(@"  quasiquote-splice: Value: %@", [value stringValue]);
            
            if (value != [NSNull NU_null] && [value atom]) {
                [NSException raise:@"NuQuasiquoteSpliceNoListError"
                            format:@"An atom was passed to Quasiquote splicer.  Splicing can only splice a list."];
            }
            
            id value_cursor = value;
            
            while (value_cursor && (value_cursor != [NSNull NU_null])) {
                id value_item = [value_cursor car];
                
                if (result_cursor == [NSNull NU_null]) {
                    result_cursor = [[[NuCell alloc] init] autorelease];
                    result = result_cursor;
                }
                else {
                    [result_cursor setCdr: [[[NuCell alloc] init] autorelease]];
                    result_cursor = [result_cursor cdr];
                }
                
                [result_cursor setCar: value_item];
                value_cursor = [value_cursor cdr];
            }
            
            QuasiLog(@"  quasiquote-splice-append: result: %@", [result stringValue]);
            
            cursor = [cursor cdr];
            
            // Don't want to do the normal cursor handling at bottom of the loop
            // in this case as we've already done it in the splicing above...
            continue;
        }
        else {
            QuasiLog(@"quasiquote: recursive callWithArguments: %@", [[cursor car] stringValue]);
            value = [self evalQuasiquote:[cursor car] context:context];
            QuasiLog(@"quasiquote: leaving recursive call with value: %@", [value stringValue]);
        }
        
        if (result == [NSNull NU_null]) {
            result = [[[NuCell alloc] init] autorelease];
            result_cursor = result;
        }
        else {
            [result_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            result_cursor = [result_cursor cdr];
        }
        
        [result_cursor setCar:value];
        
        QuasiLog(@"quasiquote: result_cursor: %@", [result_cursor stringValue]);
        QuasiLog(@"quasiquote: result:        %@", [result stringValue]);
        
        cursor = [cursor cdr];
    }
    QuasiLog(@"quasiquote: returning result = %@", [result stringValue]);
    return result;
}

#if 0
@implementation Nu_append_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id newList = [NSNull NU_null];
    id cursor = nil;
    id list_to_append = cdr;
    while (list_to_append && (list_to_append != [NSNull NU_null])) {
        id item_to_append = [[list_to_append car] evalWithContext:context];
        while (item_to_append && (item_to_append != [NSNull NU_null])) {
            if (newList == [NSNull NU_null]) {
                newList = [[[NuCell alloc] init] autorelease];
                cursor = newList;
            }
            else {
                [cursor setCdr: [[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
            }
            id item = [item_to_append car];
            [cursor setCar: item];
            item_to_append = [item_to_append cdr];
        }
        list_to_append = [list_to_append cdr];
    }
    return newList;
}

@end
#endif

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [[self evalQuasiquote:cdr context:context] car];
}

@end

@interface Nu_context_operator : NuOperator
@end

@implementation Nu_context_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return context;
}

@end

@interface Nu_set_operator : NuOperator
@end

@implementation Nu_set_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    
    NuSymbol *symbol = [cdr car];
    id value = [[cdr cdr] car];
    id result = [value evalWithContext:context];
    
    char c = (char) [[symbol stringValue] characterAtIndex:0];
    if (c == '$') {
        [symbol setValue:result];
    }
    else if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context lookupObjectForKey:[symbolTable symbolWithString:@"self"]];
        id ivar = [[symbol stringValue] substringFromIndex:1];
        [object setValue:result forIvar:ivar];
    }
    else {
#ifndef CLOSE_ON_VALUES
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id classSymbol = [symbolTable symbolWithString:@"_class"];
        id searchContext = context;
        while (searchContext) {
            if ([searchContext objectForKey:symbol]) {
                [searchContext setPossiblyNullObject:result forKey:symbol];
                return result;
            }
            else if ([searchContext objectForKey:classSymbol]) {
                break;
            }
            searchContext = [searchContext objectForKey:PARENT_KEY];
        }
#endif
        [context setPossiblyNullObject:result forKey:symbol];
    }
    return result;
}

@end

@interface Nu_local_operator : NuOperator
@end

@implementation Nu_local_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    
    NuSymbol *symbol = [cdr car];
    id value = [[cdr cdr] car];
    id result = [value evalWithContext:context];
    [context setPossiblyNullObject:result forKey:symbol];
    return result;
}
@end


@interface Nu_global_operator : NuOperator
@end

@implementation Nu_global_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    
    NuSymbol *symbol = [cdr car];
    id value = [[cdr cdr] car];
    id result = [value evalWithContext:context];
    [symbol setValue:result];
    return result;
}

@end

@interface Nu_regex_operator : NuOperator
@end

@implementation Nu_regex_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id value = [cdr car];
    value = [value evalWithContext:context];
    return [NSRegularExpression regexWithPattern:value];
}

@end

@interface Nu_do_operator : NuOperator
@end

@implementation Nu_do_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id args = [cdr car];
    id body = [cdr cdr];
    NuBlock *block = [[[NuBlock alloc] initWithParameters:args body:body context:context] autorelease];
    return block;
}

@end

@interface Nu_function_operator : NuOperator
@end

@implementation Nu_function_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id symbol = [cdr car];
    id args = [[cdr cdr] car];
    id body = [[cdr cdr] cdr];
    NuBlock *block = [[[NuBlock alloc] initWithParameters:args body:body context:context] autorelease];
    // this defines the function in the calling context, lexical closures make recursion possible
    [context setPossiblyNullObject:block forKey:symbol];
#ifdef CLOSE_ON_VALUES
    // in this case, we don't have closures, so we set this to allow recursion (but it creates a retain cycle)
    [[block context] setPossiblyNullObject:block forKey:symbol];
#endif
    return block;
}

@end

@interface Nu_label_operator : NuOperator
@end

@implementation Nu_label_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id symbol = [cdr car];
    id value = [[cdr cdr] car];
    value = [value evalWithContext:context];
    if (nu_objectIsKindOfClass(value, [NuBlock class])) {
        //NSLog(@"setting context[%@] = %@", symbol, value);
        [((NSMutableDictionary *)[value context]) setPossiblyNullObject:value forKey:symbol];
    }
    return value;
}

@end

@interface Nu_macro_0_operator : NuOperator
@end

@implementation Nu_macro_0_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id name = [cdr car];
    id body = [cdr cdr];
    
    NuMacro_0 *macro = [[[NuMacro_0 alloc] initWithName:name body:body] autorelease];
    // this defines the function in the calling context
    [context setPossiblyNullObject:macro forKey:name];
    return macro;
}

@end

@interface Nu_macro_1_operator : NuOperator
@end

@implementation Nu_macro_1_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id name = [cdr car];
    id args = [[cdr cdr] car];
    id body = [[cdr cdr] cdr];
    
    NuMacro_1 *macro = [[[NuMacro_1 alloc] initWithName:name parameters:args body:body] autorelease];
    // this defines the function in the calling context
    [context setPossiblyNullObject:macro forKey:name];
    return macro;
}

@end

@interface Nu_macrox_operator : NuOperator
@end

@implementation Nu_macrox_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id call = [cdr car];
    id name = [call car];
    id margs = [call cdr];
    
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id macro = [context objectForKey:[symbolTable symbolWithString:[name stringValue]]];
    
    if (macro == nil) {
        [NSException raise:@"NuMacroxWrongType" format:@"macrox was called on an object which is not a macro"];
    }
    
    id expanded = [macro expand1:margs context:context];
    return expanded;
}

@end

@interface Nu_list_operator : NuOperator
@end

@implementation Nu_list_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr eachEvaluatedListInContext:context];
}

@end

@interface Nu_add_operator : NuOperator 
@end

@implementation Nu_add_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([context objectForKey:[symbolTable symbolWithString:@"_class"]] && ![context objectForKey:[symbolTable symbolWithString:@"_method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as a "cmethod" call
        NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
        [classWrapper registerClass];
        Class classToExtend = [classWrapper wrappedClass];
        return help_add_method_to_class(classToExtend, cdr, context, YES);
    }
    // otherwise, it's an addition
    id firstArgument = [[cdr car] evalWithContext:context];
    if (nu_objectIsKindOfClass(firstArgument, [NSValue class])) {
        return [cdr reduce:^id(id sum, id object, NSMutableDictionary *context) {
            return @([sum doubleValue] + [[object evalWithContext:context] doubleValue]);
        } initial:@0 context:context];
    }
    else {
        return [cdr reduce:^id(id sum, id object, NSMutableDictionary *context) {
            id car = [object evalWithContext:context];
            if (car && car != [NSNull NU_null]) {
                [sum appendString:[car stringValue]];
            }
            return sum;
        } initial:[NSMutableString string] context:context];
    }
}

@end

@interface Nu_multiply_operator : NuOperator
@end

@implementation Nu_multiply_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr reduce:^id(id sum, id obj, NSMutableDictionary *context) {
        return @([sum doubleValue] * [[obj evalWithContext:context] doubleValue]);
    } initial:@1 context:context];
}

@end

@interface Nu_subtract_operator : NuOperator
@end

@implementation Nu_subtract_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([context objectForKey:[symbolTable symbolWithString:@"_class"]] && ![context objectForKey:[symbolTable symbolWithString:@"_method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as an "imethod" call
        NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
        [classWrapper registerClass];
        Class classToExtend = [classWrapper wrappedClass];
        return help_add_method_to_class(classToExtend, cdr, context, NO);
    }

    
    double sum = [[[cdr car] evalWithContext:context] doubleValue];
    if ([cdr cdr] == nil || [cdr cdr] == [NSNull NU_null]) {
        return @(-sum);
    }
    
    for (id cursor in [[cdr cdr] cellEnumerator]) {
        sum -= [[[cursor car] evalWithContext:context] doubleValue];
    }
    return [NSNumber numberWithDouble:sum];
}

@end

@interface Nu_exponentiation_operator : NuOperator
@end

@implementation Nu_exponentiation_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id cursor = cdr;
    double result = [[[cursor car] evalWithContext:context] doubleValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != [NSNull NU_null])) {
        result = pow(result, [[[cursor car] evalWithContext:context] doubleValue]);
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithDouble:result];
}

@end

@interface Nu_divide_operator : NuOperator
@end

@implementation Nu_divide_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    double product = [[[cdr car] evalWithContext:context] doubleValue];
    for (id cursor in [[cdr cdr] cellEnumerator]) {
        product /= [[[cursor car] evalWithContext:context] doubleValue];
    }
    return @(product);
}

@end

@interface Nu_modulus_operator : NuOperator
@end

@implementation Nu_modulus_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    int product = [[[cdr car] evalWithContext:context] intValue];
    for (id cursor in [[cdr cdr] cellEnumerator]) {
        product %= [[[cursor car] evalWithContext:context] intValue];
    }
    return [NSNumber numberWithInt:product];
}

@end

@interface Nu_bitwiseand_operator : NuOperator
@end

@implementation Nu_bitwiseand_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    long result = [[[cdr car] evalWithContext:context] longValue];
    for (id cursor in [[cdr cdr] cellEnumerator]) {
         result &= [[[cursor car] evalWithContext:context] longValue];
    }
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_bitwiseor_operator : NuOperator
@end

@implementation Nu_bitwiseor_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    long result = [[[cdr car] evalWithContext:context] longValue];
    for (id cursor in [[cdr cdr] cellEnumerator]) {
        result |= [[[cursor car] evalWithContext:context] longValue];
    }
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_greaterthan_operator : NuOperator
@end

@implementation Nu_greaterthan_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr allChainedPairs:^BOOL(id value1, id value2) {
        return [value1 compare:value2] == NSOrderedDescending;
    } context:context];
}

@end

@interface Nu_lessthan_operator : NuOperator
@end

@implementation Nu_lessthan_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr allChainedPairs:^BOOL(id value1, id value2) {
        return [value1 compare:value2] == NSOrderedAscending;
    } context:context];
}

@end

@interface Nu_gte_operator : NuOperator
@end

@implementation Nu_gte_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr allChainedPairs:^BOOL(id value1, id value2) {
        NSComparisonResult result = [value1 compare:value2];
        return result == NSOrderedDescending || result == NSOrderedSame;
    } context:context];
}

@end

@interface Nu_lte_operator : NuOperator
@end

@implementation Nu_lte_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr allChainedPairs:^BOOL(id value1, id value2) {
        NSComparisonResult result = [value1 compare:value2];
        return result == NSOrderedAscending || result == NSOrderedSame;
    } context:context];
}

@end

@interface Nu_leftshift_operator : NuOperator
@end

@implementation Nu_leftshift_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    long result = [[[cdr car] evalWithContext:context] longValue];
    result = result << [[[[cdr cdr] car] evalWithContext:context] longValue];
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_rightshift_operator : NuOperator
@end

@implementation Nu_rightshift_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    long result = [[[cdr car] evalWithContext:context] longValue];
    result = result >> [[[[cdr cdr] car] evalWithContext:context] longValue];
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_and_operator : NuOperator
@end

@implementation Nu_and_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id value = [NSNull NU_null];
    for (id cursor in [cdr cellEnumerator]) {
        value = [[cursor car] evalWithContext:context];
        if (!nu_valueIsTrue(value)) return [NSNull NU_null];
    }
    return value;
}

@end

@interface Nu_or_operator : NuOperator
@end

@implementation Nu_or_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    for (id cursor in [cdr cellEnumerator]) {
        id value = [[cursor car] evalWithContext:context];
        if (nu_valueIsTrue(value)) return value;
    }
    return [NSNull NU_null];
}

@end

@interface Nu_not_operator : NuOperator
@end

@implementation Nu_not_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id cursor = cdr;
    if (cursor && (cursor != [NSNull NU_null])) {
        id value = [[cursor car] evalWithContext:context];
        return nu_valueIsTrue(value) ? [NSNull NU_null] : [symbolTable symbolWithString:@"t"];
    }
    return [NSNull NU_null];
}

@end

#if !TARGET_OS_IPHONE
@interface NuConsoleViewController : NSObject
- (void) write:(id) string;
@end
#endif

@interface Nu_puts_operator : NuOperator
@end

@implementation Nu_puts_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
#if !TARGET_OS_IPHONE
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuConsoleViewController *console = (NuConsoleViewController*)
    [[symbolTable symbolWithString:@"$$console"] value];
#endif
    for (id cursor in [cdr cellEnumerator]) {
        id value = [[cursor car] evalWithContext:context];
        if (value) {
            NSString *string = [value stringValue];
#if !TARGET_OS_IPHONE
            if (console && (console != [NSNull NU_null])) {
                [console write:string];
                [console write:[NSString carriageReturn]];
            }
            else {
#endif
                printf("%s\n", [string cStringUsingEncoding:NSUTF8StringEncoding]);
#if !TARGET_OS_IPHONE
            }
#endif
        }
    }
    return [NSNull NU_null];;
}

@end

#if !TARGET_OS_IPHONE
@interface Nu_gets_operator : NuOperator
@end

@implementation Nu_gets_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    char *input = readline("");
    NSString *result = [NSString stringWithUTF8String: input];
    return result;
}

@end
#endif

@interface Nu_print_operator : NuOperator
@end

@implementation Nu_print_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
#if !TARGET_OS_IPHONE
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuConsoleViewController *console = (NuConsoleViewController*)[[symbolTable symbolWithString:@"$$console"] value];
#endif
    for (id cursor in [cdr cellEnumerator]) {
        NSString *string = [[[cursor car] evalWithContext:context] stringValue];
#if !TARGET_OS_IPHONE
        if (console && (console != [NSNull NU_null])) {
            [console write:string];
        }
        else {
#endif
            printf("%s", [string cStringUsingEncoding:NSUTF8StringEncoding]);
#if !TARGET_OS_IPHONE
        }
#endif
    }
    return [NSNull NU_null];;
}

@end

@interface Nu_call_operator : NuOperator
@end

@implementation Nu_call_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id function = [[cdr car] evalWithContext:context];
    id arguments = [cdr cdr];
    id value = [function callWithArguments:arguments context:context];
    return value;
}

@end

@interface Nu_send_operator : NuOperator
@end

@implementation Nu_send_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id target = [[cdr car] evalWithContext:context];
    id message = [cdr cdr];
    id value = [target sendMessage:message withContext:context];
    return value;
}

@end

@interface Nu_progn_operator : NuOperator
@end

@implementation Nu_progn_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [cdr evalAsPrognInContext:context];
}

@end

@interface Nu_eval_operator : NuOperator
@end

@implementation Nu_eval_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id value = [[[cdr car] evalWithContext:context] evalWithContext:context];
    return value;
}

@end

@interface Nu_load_operator : NuOperator
@end

@implementation Nu_load_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
    id resourceName = [[cdr car] evalWithContext:context];
    
    // does the resourceName contain a colon? if so, it's a framework:nu-source-file pair.
    NSArray *split = [resourceName componentsSeparatedByString:@":"];
    if ([split count] == 2) {
        id frameworkName = [split objectAtIndex:0];
        id nuFileName = [split objectAtIndex:1];
        NSBundle *framework = [NSBundle frameworkWithName:frameworkName];
        if ([framework loadNuFile:nuFileName withContext:context])
            return [symbolTable symbolWithString:@"t"];
        else {
            [NSException raise:@"NuLoadFailed" format:@"unable to load %@", resourceName];
            return nil;
        }
    }
    else {
        // first try to find a file at the specified path
        id fileName = [resourceName stringByExpandingTildeInPath];
        if (![NSFileManager fileExistsNamed:fileName]) {
            // if that failed, try looking for a Nu_ source file in the current directory,
            // first with and then without the ".nu" suffix
            fileName = [NSString stringWithFormat:@"./%@.nu", resourceName];
            if (![NSFileManager fileExistsNamed: fileName]) {
                fileName = [NSString stringWithFormat:@"./%@", resourceName];
                if (![NSFileManager fileExistsNamed: fileName]) fileName = nil;
            }
        }
        if (fileName) {
            NSString *string = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
            if (string) {
                id body = [parser parse:string asIfFromFilename:[fileName cStringUsingEncoding:NSUTF8StringEncoding]];
                [body evalWithContext:context];
                return [symbolTable symbolWithString:@"t"];
            }
            else {
                [NSException raise:@"NuLoadFailed" format:@"unable to load %@", fileName];
                return nil;
            }
        }
        
        // if that failed, try to load the file the main application bundle
        if ([[NSBundle mainBundle] loadNuFile:resourceName withContext:context])
            return [symbolTable symbolWithString:@"t"];
        
        // next, try the main Nu bundle
        if ([Nu loadNuFile:resourceName fromBundleWithIdentifier:@"nu.programming.framework" withContext:context])
            return [symbolTable symbolWithString:@"t"];
        
        // if no file was found, try to load a framework with the given name
        if ([NSBundle frameworkWithName:resourceName])
            return [symbolTable symbolWithString:@"t"];
        
        [NSException raise:@"NuLoadFailed" format:@"unable to load %@", resourceName];
        return nil;
    }
}

@end

@interface Nu_let_operator : NuOperator
@end

@implementation Nu_let_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id result = nil;
    
    @autoreleasepool {
        id arg_names = [[NuCell alloc] init];
        id arg_values = [[NuCell alloc] init];
        
        id cursor = [cdr car];
        if ((cursor != [NSNull null]) && [[cursor car] atom]) {
            [arg_names setCar:[cursor car]];
            [arg_values setCar:[[cursor cdr] car]];
        }
        else {
            id arg_name_cursor = arg_names;
            id arg_value_cursor = arg_values;
            while (cursor && (cursor != [NSNull NU_null])) {
                [arg_name_cursor setCar:[[cursor car] car]];
                [arg_value_cursor setCar:[[[cursor car] cdr] car]];
                cursor = [cursor cdr];
                if (cursor && (cursor != [NSNull NU_null])) {
                    [arg_name_cursor setCdr:[[[NuCell alloc] init] autorelease]];
                    [arg_value_cursor setCdr:[[[NuCell alloc] init] autorelease]];
                    arg_name_cursor = [arg_name_cursor cdr];
                    arg_value_cursor = [arg_value_cursor cdr];
                }
            }
        }
        id body = [cdr cdr];
        NuBlock *block = [[NuBlock alloc] initWithParameters:arg_names body:body context:context];
        result = [[block evalWithArguments:arg_values context:context] retain];
        [block release];
        
        [arg_names release];
        [arg_values release];
    }
    
    [result autorelease];
    return result;
}

@end

@interface Nu_class_operator : NuOperator
@end

@implementation Nu_class_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id className = [cdr car];
    id body;
#if defined(__x86_64__) || TARGET_OS_IPHONE
    Class newClass = nil;
#endif
    
    NuClass *childClass;
    //NSLog(@"class name: %@", className);
    if ([cdr cdr]
        && ([cdr cdr] != [NSNull NU_null])
        && [[[cdr cdr] car] isEqual: [symbolTable symbolWithString:@"is"]]
        ) {
        id parentName = [[[cdr cdr] cdr] car];
        //NSLog(@"parent name: %@", [parentName stringValue]);
        Class parentClass = NSClassFromString([parentName stringValue]);
        if (!parentClass)
            [NSException raise:@"NuUndefinedSuperclass" format:@"undefined superclass %@", [parentName stringValue]];
        
#if defined(__x86_64__) || TARGET_OS_IPHONE
        
        newClass = objc_allocateClassPair(parentClass, [[className stringValue] cStringUsingEncoding:NSUTF8StringEncoding], 0);
        childClass = [NuClass classWithClass:newClass];
        [childClass setRegistered:NO];
        //NSLog(@"created class %@", [childClass name]);
        // it seems dangerous to call this here. Maybe it's better to wait until the new class is registered.
        if ([parentClass respondsToSelector:@selector(inheritedByClass:)]) {
            [parentClass inheritedByClass:childClass];
        }
        
        if (!childClass) {
            // This class may have already been defined previously
            // (perhaps by loading the same .nu file twice).
            // If so, the above call to objc_allocateClassPair() returns nil.
            // So if childClass is nil, it may be that the class was
            // already defined, so we'll try to find it and use it.
            Class existingClass = NSClassFromString([className stringValue]);
            if (existingClass) {
                childClass = [NuClass classWithClass:existingClass];
                //if (childClass)
                //    NSLog(@"Warning: attempting to re-define existing class: %@.  Ignoring.", [className stringValue]);
            }
        }
        
#else
        [parentClass createSubclassNamed:[className stringValue]];
        childClass = [NuClass classWithName:[className stringValue]];
#endif
        body = [[[cdr cdr] cdr] cdr];
    }
    else {
        childClass = [NuClass classWithName:[className stringValue]];
        body = [cdr cdr];
    }
    if (!childClass)
        [NSException raise:@"NuUndefinedClass" format:@"undefined class %@", [className stringValue]];
    id result = nil;
    if (body && (body != [NSNull NU_null])) {
        NuBlock *block = [[NuBlock alloc] initWithParameters:[NSNull NU_null] body:body context:context];
        [[block context]
         setPossiblyNullObject:childClass
         forKey:[symbolTable symbolWithString:@"_class"]];
        result = [block evalWithArguments:[NSNull NU_null] context:[NSNull NU_null]];
        [block release];
    }
#if defined(__x86_64__) || TARGET_OS_IPHONE
    if (newClass && ([childClass isRegistered] == NO)) {
        [childClass registerClass];
    }
#endif
    return result;
}

@end

@interface Nu_ivar_operator : NuOperator
@end

@implementation Nu_ivar_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
    // this will only work if the class is unregistered...
    if ([classWrapper isRegistered]) {
        [NSException raise:@"NuIvarAddedTooLate" format:@"explicit instance variables must be added when a class is created and before any method declarations"];
    }
    Class classToExtend = [classWrapper wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"instance variable declaration with no enclosing class declaration"];
    id cursor = cdr;
    while (cursor && (cursor != [NSNull NU_null])) {
        id variableType = [cursor car];
        cursor = [cursor cdr];
        id variableName = [cursor car];
        cursor = [cursor cdr];
        NSString *signature = signature_for_identifier(variableType, symbolTable);
        nu_class_addInstanceVariable_withSignature(classToExtend,
                                                   [[variableName stringValue] cStringUsingEncoding:NSUTF8StringEncoding],
                                                   [signature cStringUsingEncoding:NSUTF8StringEncoding]);
        //NSLog(@"adding ivar %@ with signature %@", [variableName stringValue], signature);
    }
    return [NSNull NU_null];
}

@end

@interface Nu_system_operator : NuOperator
@end

@implementation Nu_system_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    NSString *command = [cdr reduce:^id(id sum, id obj, NSMutableDictionary *context) {
        [sum appendString:obj];
        return sum;
    } initial:[NSMutableString string] context:context];

    const char *commandString = [command cStringUsingEncoding:NSUTF8StringEncoding];
    int result = system(commandString) >> 8;      // this needs an explanation
    return [NSNumber numberWithInt:result];
}

@end

@interface Nu_exit_operator : NuOperator
@end

@implementation Nu_exit_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    if (cdr && (cdr != [NSNull NU_null])) {
        int status = [[[cdr car] evalWithContext:context] intValue];
        exit(status);
    }
    else {
        exit (0);
    }
    return [NSNull NU_null];                              // we'll never get here.
}

@end

@interface Nu_sleep_operator : NuOperator
@end

@implementation Nu_sleep_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    int result = -1;
    if (cdr && (cdr != [NSNull NU_null])) {
        int seconds = [[[cdr car] evalWithContext:context] intValue];
        result = sleep(seconds);
    }
    else {
        [NSException raise: @"NuArityError" format:@"sleep expects 1 argument, got 0"];
    }
    return [NSNumber numberWithInt:result];
}

@end

@interface Nu_uname_operator : NuOperator
@end

@implementation Nu_uname_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    if (!cdr || (cdr == [NSNull NU_null])) {
#if TARGET_OS_IPHONE
        return @"iOS";
#else
        return @"Darwin";
#endif
    }
    if ([[[cdr car] stringValue] isEqualToString:@"systemName"]) {
#if TARGET_OS_IPHONE
        return [[UIDevice currentDevice] systemName];
#else
        return @"Macintosh";
#endif
    }
    return nil;
}

@end

@interface Nu_help_operator : NuOperator
@end

@implementation Nu_help_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id object = [[cdr car] evalWithContext:context];
    return [object help];
}

@end

@interface Nu_break_operator : NuOperator
@end

@implementation Nu_break_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    @throw [[[NuBreakException alloc] init] autorelease];
    return nil;                                   // unreached
}

@end

@interface Nu_continue_operator : NuOperator
@end

@implementation Nu_continue_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    @throw [[[NuContinueException alloc] init] autorelease];
    return nil;                                   // unreached
}

@end

@interface Nu_return_operator : NuOperator
@end

@implementation Nu_return_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id value = nil;
    if (cdr && cdr != [NSNull NU_null]) {
        value = [[cdr car] evalWithContext:context];
    }
    @throw [[[NuReturnException alloc] initWithValue:value] autorelease];
    return nil;                                   // unreached
}

@end

@interface Nu_return_from_operator : NuOperator
@end

@implementation Nu_return_from_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id block = nil;
    id value = nil;
    id cursor = cdr;
    if (cursor && cursor != [NSNull NU_null]) {
        block = [[cursor car] evalWithContext:context];
        cursor = [cursor cdr];
    }
    if (cursor && cursor != [NSNull NU_null]) {
        value = [[cursor car] evalWithContext:context];
    }
    @throw [[[NuReturnException alloc] initWithValue:value blockForReturn:block] autorelease];
    return nil;                                   // unreached
}

@end

@interface Nu_version_operator : NuOperator
@end

@implementation Nu_version_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [NSString stringWithFormat:@"Nu %s (%s)", NU_VERSION, NU_RELEASE_DATE];
}

@end

@interface Nu_min_operator : NuOperator
@end

@implementation Nu_min_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    if (cdr == [NSNull NU_null]) [NSException raise: @"NuArityError" format:@"min expects at least 1 argument, got 0"];
    
    id smallest = [[cdr car] evalWithContext:context];
    for (id cursor in [[cdr cdr] cellEnumerator]) {
        id nextValue = [[cursor car] evalWithContext:context];
        if([smallest compare:nextValue] == 1) {
            smallest = nextValue;
        }
    }
    
    return smallest;
}

@end

@interface Nu_max_operator : NuOperator
@end

@implementation Nu_max_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    if (cdr == [NSNull NU_null]) [NSException raise: @"NuArityError" format:@"max expects at least 1 argument, got 0"];
    
    id biggest = [[cdr car] evalWithContext:context];
    for (id cursor in [[cdr cdr] cellEnumerator]) {
        id nextValue = [[cursor car] evalWithContext:context];
        if([biggest compare:nextValue] == NSOrderedAscending) {
            biggest = nextValue;
        }
    }
    return biggest;
}

@end


@interface Nu_array_operator : NuOperator
@end

@implementation Nu_array_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [NSArray arrayWithList:[cdr eachEvaluatedListInContext:context]];
}

@end

@interface Nu_dict_operator : NuOperator
@end

@implementation Nu_dict_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return [NSDictionary dictionaryWithList:[cdr eachEvaluatedListInContext:context]];
}

@end

@interface Nu_parse_operator : NuOperator
@end

@implementation Nu_parse_operator

// parse operator; parses a string into Nu code objects
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    id parser = [[[NuParser alloc] init] autorelease];
    return [parser parse:[[cdr car] evalWithContext:context]];
}

@end

@interface Nu_signature_operator : NuOperator
@end

@implementation Nu_signature_operator

// signature operator; basically gives access to the static signature_for_identifier function from within Nu code
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    return signature_for_identifier( [[cdr car] evalWithContext:context],[NuSymbolTable sharedSymbolTable]);
}

@end


#pragma mark - NuParser.m

typedef NS_ENUM(NSInteger, NUPaserState) {
    NUPaserStateNormal,
    NUPaserStateComment,
    NUPaserStateString,
    NUPaserStateHereString,
    NUPaserStateRegex,
};

#define MAX_FILES 1024
static char *g_filenames[MAX_FILES];
static int g_filecount = 0;

// Turn debug output on and off for this file only
//#define PARSER_DEBUG 1

#ifdef PARSER_DEBUG
#define ParserDebug(arg...) NSLog(arg)
#else
#define ParserDebug(arg...)
#endif

static const char *nu_parsedFilename(int i){
    return (i < 0) ? NULL: g_filenames[i];
}



static id atomWithString(NSString *string, NuSymbolTable *symbolTable){
    const char *cstring = [string cStringUsingEncoding:NSUTF8StringEncoding];
    char *endptr;
    // If the string can be converted to a long, it's an NSNumber.
    long lvalue = strtol(cstring, &endptr, 0);
    if (*endptr == 0) {
        return [NSNumber numberWithLong:lvalue];
    }
    // If the string can be converted to a double, it's an NSNumber.
    double dvalue = strtod(cstring, &endptr);
    if (*endptr == 0) {
        return [NSNumber numberWithDouble:dvalue];
    }
    // Otherwise, it's a symbol.
    NuSymbol *symbol = [symbolTable symbolWithString:string];
    return symbol;
}

static id regexWithString(NSString *string){
    // If the first character of the string is a forward slash, it's a regular expression literal.
    if (([string characterAtIndex:0] == '/') && ([string length] > 1)) {
        NSUInteger lastSlash = [string length];
        NSInteger i = lastSlash-1;
        while (i > 0) {
            if ([string characterAtIndex:i] == '/') {
                lastSlash = i;
                break;
            }
            i--;
        }
        // characters after the last slash specify options.
        NSInteger options = 0;
        NSInteger j;
        for (j = lastSlash+1; j < [string length]; j++) {
            unichar c = [string characterAtIndex:j];
            switch (c) {
                case 'i': options += NSRegularExpressionCaseInsensitive; break;
                case 's': options += NSRegularExpressionDotMatchesLineSeparators; break;
                case 'x': options += NSRegularExpressionAllowCommentsAndWhitespace; break;
                case 'm': options += NSRegularExpressionAnchorsMatchLines; break; // multiline
                default:
                    [NSException raise:@"NuParseError" format:@"unsupported regular expression option character: %C", c];
            }
        }
        NSString *pattern = [string substringWithRange:NSMakeRange(1, lastSlash-1)];
        return [NSRegularExpression regularExpressionWithPattern:pattern
                                                         options:options
                                                           error:NULL];
    }
    else {
        return nil;
    }
}

#define NU_MAX_PARSER_MACRO_DEPTH 1000

@interface NuParser (){
	int _readerMacroDepth[NU_MAX_PARSER_MACRO_DEPTH];
}

@property (nonatomic) int filenum;
@property (nonatomic) int linenum;

@property (nonatomic) BOOL parseEscapes;

@property (nonatomic, strong) NuCell *root;
@property (nonatomic, strong) NuCell *current;
@property (nonatomic) BOOL addToCar;

@property (nonatomic, strong) NSMutableString *hereString;
@property (nonatomic) BOOL hereStringOpened;

@property (nonatomic, strong) NuStack *stack;

@property (nonatomic, strong) NSMutableString *partial;
@property (nonatomic, strong) NSMutableString *comments;
@property (nonatomic, copy) NSString *pattern; // used for herestrings

@property (nonatomic, strong) NSMutableArray *readerMacroStack;

@property (nonatomic) NUPaserState state;
@property (nonatomic) int depth;
@property (nonatomic, strong) NuStack *opens;
@property (nonatomic, strong) NSMutableDictionary *context;
@property (nonatomic, strong) NuSymbolTable * symbolTable;


- (NSString *) stringValue;
- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding;
- (id) init;
- (void) openList;
- (void) closeList;
- (void) addAtom:(id)atom;
- (void) quoteNextElement;
- (void) quasiquoteNextElement;
- (void) quasiquoteEvalNextElement;
- (void) quasiquoteSpliceNextElement;
#if !TARGET_OS_IPHONE
- (int) interact;
#endif
@end

@implementation NuParser

+ (const char *) filename:(int)i{
    if ((i < 0) || (i >= g_filecount))
        return "";
    else
        return g_filenames[i];
}

- (void) setFilename:(const char *) name{
    if (name == NULL)
        _filenum = -1;
    else {
        g_filenames[g_filecount] = strdup(name);
        _filenum = g_filecount;
        g_filecount++;
    }
    _linenum = 1;
}

- (const char *) filename{
    if (_filenum == -1)
        return NULL;
    else
        return g_filenames[_filenum];
}

- (BOOL) incomplete{
    return (_depth > 0) || (_state == NUPaserStateRegex) || (_state == NUPaserStateHereString);
}


- (NSString *) stringValue{
    return [self description];
}

- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding{
    return [[self stringValue] cStringUsingEncoding:encoding];
}

- (void) reset{
    _state = NUPaserStateNormal;
    [_partial setString:@""];
    _depth = 0;
    
    [_readerMacroStack removeAllObjects];
    
    for (int i = 0; i < NU_MAX_PARSER_MACRO_DEPTH; i++) {
        _readerMacroDepth[i] = 0;
    }
    
    [_root release];
    _root = _current = [[NuCell alloc] init];
    [_root setFile:_filenum line:_linenum];
    [_root setCar:[_symbolTable symbolWithString:@"progn"]];
    _addToCar = false;
    [_stack release];
    _stack = [[NuStack alloc] init];
}

- (id) init{
    if ((self = [super init])) {
        _filenum = -1;
        _linenum = 1;
        _opens = [[NuStack alloc] init];
        // attach to symbol table (or create one if we want a separate table per parser)
        _symbolTable = [[NuSymbolTable sharedSymbolTable] retain];
        // create top-level context
        _context = [[NSMutableDictionary alloc] init];
        
        _readerMacroStack = [[NSMutableArray alloc] init];
        
        [_context setPossiblyNullObject:self forKey:[_symbolTable symbolWithString:@"_parser"]];
        [_context setPossiblyNullObject:_symbolTable forKey:SYMBOLS_KEY];
        
        _partial = [[NSMutableString alloc] initWithString:@""];
        
        [self reset];
    }
    return self;
}

- (void) close{
    // break this retain cycle so the parser can be deleted.
    [_context setPossiblyNullObject:[NSNull null] forKey:[_symbolTable symbolWithString:@"_parser"]];
}

- (void) dealloc{
    [_opens release];
    [_context release];
    [_symbolTable release];
    [_root release];
    [_stack release];
    [_comments release];
    [_readerMacroStack release];
    [_pattern release];
    [_partial release];
    [super dealloc];
}

- (void) addAtomCell:(id)atom{
    ParserDebug(@"addAtomCell: depth = %d  atom = %@", _depth, [atom stringValue]);
    
    // when we have two consecutive labels, concatenate them.
    // this allows us to have ':' characters inside labels.
    if ([atom isKindOfClass:[NuSymbol class]] && [atom isLabel]) {	
        id currentCar = [_current car];
        if ([currentCar isKindOfClass:[NuSymbol class]] && [currentCar isLabel]) {
            NuSymbol *combinedLabel = [_symbolTable symbolWithString:[[currentCar stringValue] stringByAppendingString:[atom stringValue]]];
            [_current setCar:combinedLabel];
            return;
        }		
    }

    NuCell *newCell;
    if (_comments) {
        NuCellWithComments *newCellWithComments = [[[NuCellWithComments alloc] init] autorelease];
        [newCellWithComments setComments:_comments];
        newCell = newCellWithComments;
        [_comments release];
        _comments = nil;
    }
    else {
        newCell = [[[NuCell alloc] init] autorelease];
        [newCell setFile:_filenum line:_linenum];
    }
    if (_addToCar) {
        [_current setCar:newCell];
        [_stack push:_current];
    }
    else {
        [_current setCdr:newCell];
    }
    _current = newCell;
    [_current setCar:atom];
    _addToCar = false;
}

- (void) openListCell{
    ParserDebug(@"openListCell: depth = %d", _depth);
    
    _depth++;
    NuCell *newCell = [[[NuCell alloc] init] autorelease];
    [newCell setFile:_filenum line:_linenum];
    if (_addToCar) {
        [_current setCar:newCell];
        [_stack push:_current];
    }
    else {
        [_current setCdr:newCell];
    }
    _current = newCell;
    
    _addToCar = true;
}

- (void) openList{
    ParserDebug(@"openList: depth = %d", _depth);
    
    while ([_readerMacroStack count] > 0) {
        ParserDebug(@"  openList: readerMacro");
        
        [self openListCell];
        ++_readerMacroDepth[_depth];
        ParserDebug(@"  openList: ++RMD[%d] = %d", _depth, _readerMacroDepth[_depth]);
        [self addAtomCell:
         [_symbolTable symbolWithString:
          [_readerMacroStack objectAtIndex:0]]];
        
        [_readerMacroStack removeObjectAtIndex:0];
    }
    
    [self openListCell];
}

- (void) addAtom:(id)atom{
    ParserDebug(@"addAtom: depth = %d  atom: %@", _depth, [atom stringValue]);
    
    while ([_readerMacroStack count] > 0) {
        ParserDebug(@"  addAtom: readerMacro");
        [self openListCell];
        ++_readerMacroDepth[_depth];
        ParserDebug(@"  addAtom: ++RMD[%d] = %d", _depth, _readerMacroDepth[_depth]);
        [self addAtomCell:
         [_symbolTable symbolWithString:[_readerMacroStack objectAtIndex:0]]];
        
        [_readerMacroStack removeObjectAtIndex:0];
    }
    
    [self addAtomCell:atom];
    
    while (_readerMacroDepth[_depth] > 0) {
        --_readerMacroDepth[_depth];
        ParserDebug(@"  addAtom: --RMD[%d] = %d", _depth, _readerMacroDepth[_depth]);
        [self closeList];
    }
}

- (void) closeListCell{
    ParserDebug(@"closeListCell: depth = %d", _depth);
    
    --_depth;
    
    if (_addToCar) {
        [_current setCar:[NSNull null]];
    }
    else {
        [_current setCdr:[NSNull null]];
        _current = [_stack pop];
    }
    _addToCar = false;
    
    while (_readerMacroDepth[_depth] > 0) {
        --_readerMacroDepth[_depth];
        ParserDebug(@"  closeListCell: --RMD[%d] = %d", _depth, _readerMacroDepth[_depth]);
        [self closeList];
    }
}

- (void) closeList{
    ParserDebug(@"closeList: depth = %d", _depth);
    
    [self closeListCell];
}

-(void) openReaderMacro:(NSString*) operator{
    [_readerMacroStack addObject:operator];
}

-(void) quoteNextElement{
    [self openReaderMacro:@"quote"];
}

-(void) quasiquoteNextElement{
    [self openReaderMacro:@"quasiquote"];
}

-(void) quasiquoteEvalNextElement{
    [self openReaderMacro:@"quasiquote-eval"];
}

-(void) quasiquoteSpliceNextElement{
    [self openReaderMacro:@"quasiquote-splice"];
}

static int nu_octal_digit_value(unichar c){
    int x = (c - '0');
    if ((x >= 0) && (x <= 7))
        return x;
    [NSException raise:@"NuParseError" format:@"invalid octal character: %C", c];
    return 0;
}

static unichar nu_hex_digit_value(unichar c){
    int x = (c - '0');
    if ((x >= 0) && (x <= 9))
        return x;
    x = (c - 'A');
    if ((x >= 0) && (x <= 5))
        return x + 10;
    x = (c - 'a');
    if ((x >= 0) && (x <= 5))
        return x + 10;
    [NSException raise:@"NuParseError" format:@"invalid hex character: %C", c];
    return 0;
}

static unichar nu_octal_digits_to_unichar(unichar c0, unichar c1, unichar c2){
    return nu_octal_digit_value(c0)*64 + nu_octal_digit_value(c1)*8 + nu_octal_digit_value(c2);
}

static unichar nu_hex_digits_to_unichar(unichar c1, unichar c2){
    return nu_hex_digit_value(c1)*16 + nu_hex_digit_value(c2);
}

static unichar nu_unicode_digits_to_unichar(unichar c1, unichar c2, unichar c3, unichar c4){
    unichar value = nu_hex_digit_value(c1)*4096 + nu_hex_digit_value(c2)*256 + nu_hex_digit_value(c3)*16 + nu_hex_digit_value(c4);
    return value;
}

static NSUInteger nu_parse_escape_sequences(NSString *string, NSUInteger i, NSUInteger imax, NSMutableString *partial){
    i++;
    unichar c = [string characterAtIndex:i];
    switch(c) {
        case 'n': [partial appendCharacter:0x0a]; break;
        case 'r': [partial appendCharacter:0x0d]; break;
        case 'f': [partial appendCharacter:0x0c]; break;
        case 't': [partial appendCharacter:0x09]; break;
        case 'b': [partial appendCharacter:0x08]; break;
        case 'a': [partial appendCharacter:0x07]; break;
        case 'e': [partial appendCharacter:0x1b]; break;
        case 's': [partial appendCharacter:0x20]; break;
        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
        {
            // octal. expect two more digits (\nnn).
            if (imax < i+2) {
                [NSException raise:@"NuParseError" format:@"not enough characters for octal constant"];
            }
            char c1 = [string characterAtIndex:++i];
            char c2 = [string characterAtIndex:++i];
            [partial appendCharacter:nu_octal_digits_to_unichar(c, c1, c2)];
            break;
        }
        case 'x':
        {
            // hex. expect two more digits (\xnn).
            if (imax < i+2) {
                [NSException raise:@"NuParseError" format:@"not enough characters for hex constant"];
            }
            char c1 = [string characterAtIndex:++i];
            char c2 = [string characterAtIndex:++i];
            [partial appendCharacter:nu_hex_digits_to_unichar(c1, c2)];
            break;
        }
        case 'u':
        {
            // unicode. expect four more digits (\unnnn)
            if (imax < i+4) {
                [NSException raise:@"NuParseError" format:@"not enough characters for unicode constant"];
            }
            char c1 = [string characterAtIndex:++i];
            char c2 = [string characterAtIndex:++i];
            char c3 = [string characterAtIndex:++i];
            char c4 = [string characterAtIndex:++i];
            [partial appendCharacter:nu_unicode_digits_to_unichar(c1, c2, c3, c4)];
            break;
        }
        case 'c': case 'C':
        {
            // control character.  Unsupported, fall through to default.
        }
        case 'M':
        {
            // meta character. Unsupported, fall through to default.
        }
        default:
            [partial appendCharacter:c];
    }
    return i;
}

-(id) parse:(NSString*)string{
    if (!string) return [NSNull null];            // don't crash, at least.
    
    int column = 0;
    if (_state != NUPaserStateRegex)
        [_partial setString:@""];
    else
        [_partial autorelease];
    
    NSUInteger i = 0;
    NSUInteger imax = [string length];
    for (i = 0; i < imax; i++) {
        column++;
        unichar stri = [string characterAtIndex:i];
        switch (_state) {
            case NUPaserStateNormal:
                switch(stri) {
                    case '(':
                        ParserDebug(@"Parser: (  %d on line %d", column, _linenum);
                        [_opens push:@(column)];
                        if ([_partial length] == 0) {
                            [self openList];
                        }
                        break;
                    case ')':
                        ParserDebug(@"Parser: )  %d on line %d", column, _linenum);
                        [_opens pop];
                        if ([_partial length] > 0) {
                            [self addAtom:atomWithString(_partial, _symbolTable)];
                            [_partial setString:@""];
                        }
                        if (_depth > 0) {
                            [self closeList];
                        }
                        else {
                            [NSException raise:@"NuParseError" format:@"no open sexpr"];
                        }
                        break;
                    case '"':
                    {
                        _state = NUPaserStateString;
                        _parseEscapes = YES;
                        [_partial setString:@""];
                        break;
                    }
                    case '-':
                    case '+':
                    {
                        if ((i+1 < imax) && ([string characterAtIndex:i+1] == '"')) {
                            _state = NUPaserStateString;
                            _parseEscapes = (stri == '+');
                            [_partial setString:@""];
                            i++;
                        }
                        else {
                            [_partial appendCharacter:stri];
                        }
                        break;
                    }
                    case '/':
                    {
                        if (i+1 < imax) {
                            unichar nextc = [string characterAtIndex:i+1];
                            if (nextc == ' ') {
                                [_partial appendCharacter:stri];
                            }
                            else {
                                _state = NUPaserStateRegex;
                                [_partial setString:@""];
                                [_partial appendCharacter:'/'];
                            }
                        }
                        else {
                            [_partial appendCharacter:stri];
                        }
                        break;
                    }
                    case ':':
                        [_partial appendCharacter:':'];
                        [self addAtom:atomWithString(_partial, _symbolTable)];
                        [_partial setString:@""];
                        break;
                    case '\'':
                    {
                        // try to parse a character literal.
                        // if that doesn't work, then interpret the quote as the quote operator.
                        bool isACharacterLiteral = false;
                        int characterLiteralValue;
                        if (i + 2 < imax) {
                            if ([string characterAtIndex:i+1] != '\\') {
                                if ([string characterAtIndex:i+2] == '\'') {
                                    isACharacterLiteral = true;
                                    characterLiteralValue = [string characterAtIndex:i+1];
                                    i = i + 2;
                                }
                                else if ((i + 5 < imax) &&
                                         isalnum([string characterAtIndex:i+1]) &&
                                         isalnum([string characterAtIndex:i+2]) &&
                                         isalnum([string characterAtIndex:i+3]) &&
                                         isalnum([string characterAtIndex:i+4]) &&
                                         ([string characterAtIndex:i+5] == '\'')) {
                                    characterLiteralValue =
                                    ((([string characterAtIndex:i+1]*256
                                       + [string characterAtIndex:i+2])*256
                                      + [string characterAtIndex:i+3])*256
                                     + [string characterAtIndex:i+4]);
                                    isACharacterLiteral = true;
                                    i = i + 5;
                                }
                            }
                            else {
                                // look for an escaped character
                                NSUInteger newi = nu_parse_escape_sequences(string, i+1, imax, _partial);
                                if ([_partial length] > 0) {
                                    isACharacterLiteral = true;
                                    characterLiteralValue = [_partial characterAtIndex:0];
                                    [_partial setString:@""];
                                    i = newi;
                                    // make sure that we have a closing single-quote
                                    if ((i + 1 < imax) && ([string characterAtIndex:i+1] == '\'')) {
                                        i = i + 1;// move past the closing single-quote
                                    }
                                    else {
                                        [NSException raise:@"NuParseError" format:@"missing close quote from character literal"];
                                    }
                                }
                            }
                        }
                        if (isACharacterLiteral) {
                            [self addAtom:[NSNumber numberWithInt:characterLiteralValue]];
                        }
                        else {
                            [self quoteNextElement];
                        }
                        break;
                    }
                    case '`':
                    {
                        [self quasiquoteNextElement];
                        break;
                    }
                    case ',':
                    {
                        if ((i + 1 < imax) && ([string characterAtIndex:i+1] == '@')) {
                            [self quasiquoteSpliceNextElement];
                            i = i + 1;
                        }
                        else {
                            [self quasiquoteEvalNextElement];
                        }
                        break;
                    }
                    case '\n':                    // end of line
                        column = 0;
                        _linenum++;
                    case ' ':                     // end of token
                    case '\t':
                    case 0:                       // end of string
                        if ([_partial length] > 0) {
                            [self addAtom:atomWithString(_partial, _symbolTable)];
                            [_partial setString:@""];
                        }
                        break;
                    case ';':
                    case '#':
                        if ((stri == '#') && ([_partial length] > 0)) {
                            // this allows us to include '#' in symbols (but not as the first character)
                            [_partial appendCharacter:'#'];
                        } else {
                            if ([_partial length]) {
                                NuSymbol *symbol = [_symbolTable symbolWithString:_partial];
                                [self addAtom:symbol];
                                [_partial setString:@""];                        
                            }
                            _state = NUPaserStateComment;
                        }
                        break;
                    case '<':
                        if ((i+3 < imax) && ([string characterAtIndex:i+1] == '<')
                            && (([string characterAtIndex:i+2] == '-') || ([string characterAtIndex:i+2] == '+'))) {
                            // parse a here string
                            _state = NUPaserStateHereString;
                            _parseEscapes = ([string characterAtIndex:i+2] == '+');
                            // get the tag to match
                            NSUInteger j = i+3;
                            while ((j < imax) && ([string characterAtIndex:j] != '\n')) {
                                j++;
                            }
                            [_pattern release];
                            _pattern = [[string substringWithRange:NSMakeRange(i+3, j-(i+3))] retain];
                            //NSLog(@"herestring pattern: %@", pattern);
                            [_partial setString:@""];
                            // skip the newline
                            i = j;
                            //NSLog(@"parsing herestring that ends with %@ from %@", pattern, [string substringFromIndex:i]);
                            _hereString = nil;
                            _hereStringOpened = true;
                            break;
                        }
                        // if this is not a here string, fall through to the general handler
                    default:
                        [_partial appendCharacter:stri];
                }
                break;
            case NUPaserStateHereString:
                //NSLog(@"pattern %@", pattern);
                if ((stri == [_pattern characterAtIndex:0]) &&
                    (i + [_pattern length] < imax) &&
                    ([_pattern isEqual:[string substringWithRange:NSMakeRange(i, [_pattern length])]])) {
                    // everything up to here is the string
                    NSString *string = [[[NSString alloc] initWithString:_partial] autorelease];
                    [_partial setString:@""];
                    if (!_hereString)
                        _hereString = [[[NSMutableString alloc] init] autorelease];
                    else
                        [_hereString appendString:@"\n"];
                    [_hereString appendString:string];
                    if (_hereString == nil)
                        _hereString = [NSMutableString string];
                    //NSLog(@"got herestring **%@**", hereString);
                    [self addAtom:_hereString];
                    // to continue, set i to point to the next character after the tag
                    i = i + [_pattern length] - 1;
                    //NSLog(@"continuing parsing with:%s", &str[i+1]);
                    //NSLog(@"ok------------");
                    _state = NUPaserStateNormal;
                }
                else {
                    if (_parseEscapes && (stri == '\\')) {
                        // parse escape sequencs in here strings
                        i = nu_parse_escape_sequences(string, i, imax, _partial);
                    }
                    else {
                        [_partial appendCharacter:stri];
                    }
                }
                break;
            case NUPaserStateString:
                switch(stri) {
                    case '"':
                    {
                        _state = NUPaserStateNormal;
                        NSString *string = [NSString stringWithString:_partial];
                        //NSLog(@"parsed string:%@:", string);
                        [self addAtom:string];
                        [_partial setString:@""];
                        break;
                    }
                    case '\n':
                    {
                        column = 0;
                        _linenum++;
                        NSString *string = [[NSString alloc] initWithString:_partial];
                        [NSException raise:@"NuParseError" format:@"partial string (terminated by newline): %@", string];
                        [_partial setString:@""];
                        break;
                    }
                    case '\\':
                    {                             // parse escape sequences in strings
                        if (_parseEscapes) {
                            i = nu_parse_escape_sequences(string, i, imax, _partial);
                        }
                        else {
                            [_partial appendCharacter:stri];
                        }
                        break;
                    }
                    default:
                    {
                        [_partial appendCharacter:stri];
                    }
                }
                break;
            case NUPaserStateRegex:
                switch(stri) {
                    case '/':                     // that's the end of it
                    {
                        [_partial appendCharacter:'/'];
                        i++;
                        // add any remaining option characters
                        while (i < imax) {
                            unichar nextc = [string characterAtIndex:i];
                            if ((nextc >= 'a') && (nextc <= 'z')) {
                                [_partial appendCharacter:nextc];
                                i++;
                            }
                            else {
                                i--;              // back up to revisit this character
                                break;
                            }
                        }
                        [self addAtom:regexWithString(_partial)];
                        [_partial setString:@""];
                        _state = NUPaserStateNormal;
                        break;
                    }
                    case '\\':
                    {
                        [_partial appendCharacter:stri];
                        i++;
                        [_partial appendCharacter:[string characterAtIndex:i]];
                        break;
                    }
                    default:
                    {
                        [_partial appendCharacter:stri];
                    }
                }
                break;
            case NUPaserStateComment:
                switch(stri) {
                    case '\n':
                    {
                        if (!_comments) _comments = [[NSMutableString alloc] init];
                        else [_comments appendString:@"\n"];
                        [_comments appendString:[[[NSString alloc] initWithString:_partial] autorelease]];
                        [_partial setString:@""];
                        column = 0;
                        _linenum++;
                        _state = NUPaserStateNormal;
                        break;
                    }
                    default:
                    {
                        [_partial appendCharacter:stri];
                    }
                }
        }
    }
    // close off anything that is still being scanned.
    if (_state == NUPaserStateNormal) {
        if ([_partial length] > 0) {
            [self addAtom:atomWithString(_partial, _symbolTable)];
        }
        [_partial setString:@""];
    }
    else if (_state == NUPaserStateComment) {
        if (!_comments) _comments = [[NSMutableString alloc] init];
        [_comments appendString:[[[NSString alloc] initWithString:_partial] autorelease]];
        [_partial setString:@""];
        column = 0;
        _linenum++;
        _state = NUPaserStateNormal;
    }
    else if (_state == NUPaserStateString) {
        [NSException raise:@"NuParseError" format:@"partial string (terminated by newline): %@", _partial];
    }
    else if (_state == NUPaserStateHereString) {
        if (_hereStringOpened) {
            _hereStringOpened = false;
        }
        else {
            if (_hereString) {
                [_hereString appendString:@"\n"];
            }
            else {
                _hereString = [[NSMutableString alloc] init];
            }
            [_hereString appendString:_partial];
            [_partial setString:@""];
        }
    }
    else if (_state == NUPaserStateRegex) {
        // we stay in this state and leave the regex open.
        [_partial appendCharacter:'\n'];
        [_partial retain];
    }
    if ([self incomplete]) {
        return [NSNull null];
    }
    else {
        NuCell *expressions = _root;
        _root = nil;
        [self reset];
        [expressions autorelease];
        return expressions;
    }
}

- (id) parse:(NSString *)string asIfFromFilename:(const char *) filename;{
    [self setFilename:filename];
    id result = [self parse:string];
    [self setFilename:NULL];
    return result;
}

- (void) newline{
    _linenum++;
}

- (id) eval: (id) code{
    return [code evalWithContext:_context];
}

- (id) valueForKey:(NSString *)string{
    return [self eval:[self parse:string]];
}

- (void) setValue:(id)value forKey:(NSString *)string{
    [_context setObject:value forKey:[_symbolTable symbolWithString:string]];
}

- (NSString *) parseEval:(NSString *)string{
    id result = nil;
    @autoreleasepool {
        NuCell *expressions = [self parse:string];
        id result = [[expressions evalWithContext:_context] stringValue];
        [result retain];
    }

    [result autorelease];
    return result;
}

#if !TARGET_OS_IPHONE
- (int) interact{
    printf("Nu Shell.\n");
    
    char* homedir = getenv("HOME");
    char  history_file[FILENAME_MAX];
    int   valid_history_file = 0;
    
    if (homedir) {                                // Not likely, but could be NULL
        // Since we're getting something from the shell environment,
        // try to be safe about it
        int n = snprintf(history_file, FILENAME_MAX, "%s/.nush_history", homedir);
        if (n <=  FILENAME_MAX) {
            read_history(history_file);
            valid_history_file = 1;
        }
    }
    
    const char *unbufferedIO = getenv("NSUnbufferedIO");
    if (unbufferedIO && !strcmp(unbufferedIO, "YES")) {
        system("stty -echo"); // Turn off echoing to avoid duplicated input. Surely there's a better way to do this.
        puts("It looks like you are running in the Xcode debugger console. Beware: command history is broken.");
    }
    
    do {
        @autoreleasepool {
            char *prompt = ([self incomplete] ? "- " : "% ");
#ifdef IPHONENOREADLINE
            puts(prompt);
            char line[1024];                          // careful
            int count = gets(line);
#else
            char *line = readline(prompt);
            if (line && *line && strcmp(line, "quit"))
                add_history (line);
#endif
            if(!line || !strcmp(line, "quit")) {
                break;
            }
            else {
                id progn = nil;
                
                @try
                {
                    progn = [[self parse:[NSString stringWithCString:line encoding:NSUTF8StringEncoding]] retain];
                }
                @catch (NuException* nuException) {
                    printf("%s\n", [[nuException dump] cStringUsingEncoding:NSUTF8StringEncoding]);
                    [self reset];
                }
                @catch (id exception) {
                    printf("%s: %s\n",
                           [[exception name] cStringUsingEncoding:NSUTF8StringEncoding],
                           [[exception reason] cStringUsingEncoding:NSUTF8StringEncoding]);
                    [self reset];
                }
                
                if (progn && (progn != [NSNull null])) {
                    id cursor = [progn cdr];
                    while (cursor && (cursor != [NSNull null])) {
                        if ([cursor car] != [NSNull null]) {
                            id expression = [cursor car];
                            //printf("evaluating %s\n", [[expression stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
                            
                            @try
                            {
                                id result = [expression evalWithContext:_context];
                                if (result) {
                                    id stringToDisplay;
                                    if ([result respondsToSelector:@selector(escapedStringRepresentation)]) {
                                        stringToDisplay = [result escapedStringRepresentation];
                                    }
                                    else {
                                        stringToDisplay = [result stringValue];
                                    }
                                    printf("%s\n", [stringToDisplay cStringUsingEncoding:NSUTF8StringEncoding]);
                                }
                            }
                            @catch (NuException* nuException) {
                                printf("%s\n", [[nuException dump] cStringUsingEncoding:NSUTF8StringEncoding]);
                            }
                            @catch (id exception) {
                                printf("%s: %s\n",
                                       [[exception name] cStringUsingEncoding:NSUTF8StringEncoding],
                                       [[exception reason] cStringUsingEncoding:NSUTF8StringEncoding]);
                            }
                        }
                        cursor = [cursor cdr];
                    }
                }
                [progn release];
            }
        }
    } while(1);
    
    if (valid_history_file) {
        write_history(history_file);
    }
    
    return 0;
}
#endif


#if !TARGET_OS_IPHONE
+ (int) main{
    int result = 0;
    @autoreleasepool {
        NuParser *parser = [Nu sharedParser];
        result = [parser interact];
    }
    return result;
}
#endif

@end

#pragma mark - NuPointer.m

@interface NuPointer (){
    void *_pointer;
    NSString *_typeString;
    bool _thePointerIsMine;
}
@end

@implementation NuPointer

- (id) init{
    if ((self = [super init])) {
        _pointer = 0;
        _typeString = nil;
        _thePointerIsMine = NO;
    }
    return self;
}

- (void *) pointer {return _pointer;}

- (void) setPointer:(void *) p{
    _pointer = p;
}

- (NSString *) typeString {return _typeString;}

- (id) object{
    return _pointer;
}

- (void) setTypeString:(NSString *) s{
    [s retain];
    [_typeString release];
    _typeString = s;
}

- (void) allocateSpaceForTypeString:(NSString *) s{
    if (_thePointerIsMine)
        free(_pointer);
    [self setTypeString:s];
    const char *type = [s cStringUsingEncoding:NSUTF8StringEncoding];
    while (*type && (*type != '^'))
        type++;
    if (*type)
        type++;
    //NSLog(@"allocating space for type %s", type);
    _pointer = value_buffer_for_objc_type(type);
    _thePointerIsMine = YES;
}

- (void) dealloc{
    [_typeString release];
    if (_thePointerIsMine)
        free(_pointer);
    [super dealloc];
}

- (id) value{
    const char *type = [_typeString cStringUsingEncoding:NSUTF8StringEncoding];
    while (*type && (*type != '^'))
        type++;
    if (*type)
        type++;
    //NSLog(@"getting value for type %s", type);
    return get_nu_value_from_objc_value(_pointer, type);
}

@end

#pragma mark - NuProfiler.h

@interface NuProfileStackElement : NSObject{
@public
    NSString *name;
    uint64_t start;
    NuProfileStackElement *parent;
}

@end

@interface NuProfileTimeSlice : NSObject{
@public
    float time;
    int count;
}

@end

@implementation NuProfileStackElement

- (NSString *) name {return name;}
- (uint64_t) start {return start;}
- (NuProfileStackElement *) parent {return parent;}

- (NSString *) description{
    return [NSString stringWithFormat:@"name:%@ start:%llx", name, start];
}

@end

@implementation NuProfileTimeSlice

- (float) time {return time;}
- (int) count {return count;}

- (NSString *) description{
    return [NSString stringWithFormat:@"time:%f count:%d", time, count];
}

@end

@interface NuProfiler (){
    NSMutableDictionary *_sections;
    NuProfileStackElement *_stack;
}
@end

@implementation NuProfiler

static NuProfiler *defaultProfiler = nil;

+ (NuProfiler *) defaultProfiler{
    if (!defaultProfiler)
        defaultProfiler = [[NuProfiler alloc] init];
    return defaultProfiler;
}

- (NuProfiler *) init{
    self = [super init];
    _sections = [[NSMutableDictionary alloc] init];
    _stack = nil;
    return self;
}

- (void) start:(NSString *) name{
    NuProfileStackElement *stackElement = [[NuProfileStackElement alloc] init];
    stackElement->name = [name retain];
    stackElement->start = mach_absolute_time();
    stackElement->parent = _stack;
    _stack = stackElement;
}

- (void) stop{
    if (_stack) {
        uint64_t current_time = mach_absolute_time();
        uint64_t time_delta = current_time - _stack->start;
        struct mach_timebase_info info;
        mach_timebase_info(&info);
        float timeDelta = 1e-9 * time_delta * (double) info.numer / info.denom;
        //NSNumber *delta = [NSNumber numberWithFloat:timeDelta];
        NuProfileTimeSlice *entry = [_sections objectForKey:_stack->name];
        if (!entry) {
            entry = [[[NuProfileTimeSlice alloc] init] autorelease];
            entry->count = 1;
            entry->time = timeDelta;
            [_sections setObject:entry forKey:_stack->name];
        }
        else {
            entry->count++;
            entry->time += timeDelta;
        }
        [_stack->name release];
        NuProfileStackElement *top = _stack;
        _stack = _stack->parent;
        [top release];
    }
}

- (NSMutableDictionary *) sections{
    return _sections;
}

- (void) reset{
    [_sections removeAllObjects];
    while (_stack) {
        NuProfileStackElement *top = _stack;
        _stack = _stack->parent;
        [top release];
    }
}

@end

#pragma mark - NuProperty.m

@interface NuProperty (){
    objc_property_t _p;
}
@end

@implementation NuProperty

+ (NuProperty *) propertyWithProperty:(objc_property_t) property {
    return [[[self alloc] initWithProperty:property] autorelease];
}

- (id) initWithProperty:(objc_property_t) property{
    if ((self = [super init])) {
        _p = property;
    }
    return self;
}

- (NSString *) name{
    return [NSString stringWithCString:property_getName(_p) encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - NuReference.m

@interface NuReference (){
    id *_pointer;
    bool _thePointerIsMine;
}
@end

@implementation NuReference

- (id) init{
    if ((self = [super init])) {
        _pointer = 0;
        _thePointerIsMine = false;
    }
    return self;
}

- (id) value {return _pointer ? *_pointer : nil;}

- (void) setValue:(id) v{
    if (!_pointer) {
        _pointer = (id *) malloc (sizeof (id));
        *_pointer = nil;
        _thePointerIsMine = true;
    }
    [v retain];
    [(*_pointer) release];
    (*_pointer)  = v;
}

- (void) setPointer:(id *) p{
    if (_thePointerIsMine) {
        free(_pointer);
        _thePointerIsMine = false;
    }
    _pointer = p;
}

- (id *) pointerToReferencedObject{
    if (!_pointer) {
        _pointer = (id *) malloc (sizeof (id));
        *_pointer = nil;
        _thePointerIsMine = true;
    }
    return _pointer;
}

- (void) retainReferencedObject{
    [(*_pointer) retain];
}

- (void) dealloc{
    if (_thePointerIsMine)
        free(_pointer);
    [super dealloc];
}

@end
#pragma mark - NuRegex.m

@implementation NSTextCheckingResult (NuRegexMatch)
/*!
 @method regex
 The regular expression used to make this match. */
- (NSRegularExpression *)regex {
    return [self regularExpression];
}

/*!
 @method count
 The number of capturing subpatterns, including the pattern itself. */
- (NSUInteger)count {
    return [self numberOfRanges];
}

/*!
 @method group
 Returns the part of the target string that matched the pattern. */
- (NSString *)group {
    return [self groupAtIndex:0];
}

/*!
 @method groupAtIndex:
 Returns the part of the target string that matched the subpattern at the given index or nil if it wasn't matched. The subpatterns are indexed in order of their opening parentheses, 0 is the entire pattern, 1 is the first capturing subpattern, and so on. */
- (NSString *)groupAtIndex:(int)i {
    NSRange range = [self rangeAtIndex:i];
    NSString *string = [self associatedObjectForKey:@"string"];
    if (string && (range.location != NSNotFound)) {
 	return [string substringWithRange:range];
    } else {
        return nil;
    }
}

/*!
 @method string
 Returns the target string. */
- (NSString *)string {
    return [self associatedObjectForKey:@"string"];
}

@end

@implementation NSRegularExpression (NuRegex)

/*!
 @method regexWithPattern:
 Creates a new regex using the given pattern string. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern {
    return [self regularExpressionWithPattern:pattern
                                      options:0
                                        error:NULL];
}

/*!
 @method regexWithPattern:options:
 Creates a new regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern options:(int)options {
    return [self regularExpressionWithPattern:pattern
                                      options:options
                                        error:NULL];
}

/*!
 @method initWithPattern:
 Initializes the regex using the given pattern string. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern {
    return [self initWithPattern:pattern
                         options:0
                           error:NULL];
}

/*!
 @method initWithPattern:options:
 Initializes the regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern options:(int)options {
    return [self initWithPattern:pattern
                         options:options
                           error:NULL];
}


/*!
 @method findInString:
 Calls findInString:range: using the full range of the target string. */
- (NSTextCheckingResult *)findInString:(NSString *)string {
    NSTextCheckingResult *result = [self firstMatchInString:string
                                                    options:0
                                                      range:NSMakeRange(0,[string length])];
    if (result) {
        [result setRetainedAssociatedObject:string forKey:@"string"];
    }
    return result;
}

/*!
 @method findInString:range:
 Returns an NuRegexMatch for the first occurrence of the regex in the given range of the target string or nil if none is found. */
- (NSTextCheckingResult *)findInString:(NSString *)string range:(NSRange)range {
    NSTextCheckingResult *result = [self firstMatchInString:string
                                                    options:0
                                                      range:range];
    if (result) {
        [result setRetainedAssociatedObject:string forKey:@"string"];
    }
    return result;
}

/*!
 @method findAllInString:
 Calls findAllInString:range: using the full range of the target string. */
- (NSArray *)findAllInString:(NSString *)string {
    NSArray *result = [self matchesInString:string
                                    options:0
                                      range:NSMakeRange(0, [string length])];
    if (result) {
        for (NSObject *match in result) {
            [match setRetainedAssociatedObject:string forKey:@"string"];
        }
    }
    return result;
}

/*!
 @method findAllInString:range:
 Returns an array of all non-overlapping occurrences of the regex in the given range of the target string. The members of the array are NuRegexMatches. */
- (NSArray *)findAllInString:(NSString *)string range:(NSRange)range {
    NSArray *result = [self matchesInString:string options:0 range:range];
    if (result) {
        for (NSObject *match in result) {
            [match setRetainedAssociatedObject:string forKey:@"string"];
        }
    }
    return result;
}

/*!
 @method replaceWithString:inString:
 Calls replaceWithString:inString:limit: with no limit. */
- (NSString *)replaceWithString:(NSString *)replacement inString:(NSString *)string {
    return [self stringByReplacingMatchesInString:string
                                          options:0
                                            range:NSMakeRange(0, [string length])
                                     withTemplate:replacement];
    
}

@end

#pragma mark - NuStack.m

@interface NuStack ()
@property (nonatomic, strong) NSMutableArray *storage;
@end

@implementation NuStack
- (id) init{
    if ((self = [super init])) {
        _storage = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc{
    [_storage release];
    [super dealloc];
}

- (void) push:(id) object{
    [_storage addObject:object];
}

- (id) pop{
    if ([_storage count] > 0) {
        id object = [[_storage lastObject] retain];
        [_storage removeLastObject];
		[object autorelease];
        return object;
    }
    else {
        return nil;
    }
}

- (NSUInteger) depth{
    return [_storage count];
}

- (id) top{
    return [_storage lastObject];
}

- (id) objectAtIndex:(int) i{
	return [_storage objectAtIndex:i];
}

- (void) dump{
    for (NSInteger i = [_storage count]-1; i >= 0; i--) {
        NSLog(@"stack: %@", [_storage objectAtIndex:i]);
    }
}

@end

#pragma mark - NuSuper.m
@interface NuSuper ()
@property (nonatomic, assign) id object;
@property (nonatomic, assign) Class class;
@end

@implementation NuSuper

- (NuSuper *) initWithObject:(id) o ofClass:(Class) c{
    if ((self = [super init])) {
        _object = o; // weak reference
        _class = c; // weak reference
    }
    return self;
}

+ (NuSuper *) superWithObject:(id) o ofClass:(Class) c{
    return [[[self alloc] initWithObject:o ofClass:c] autorelease];
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context{
    // By themselves, Objective-C objects evaluate to themselves.
    if (!cdr || (cdr == [NSNull null]))
        return _object;
    
    //NSLog(@"messaging super with %@", [cdr stringValue]);
    // But when they're at the head of a list, the list is converted to a message and sent to the object
    
    NSMutableArray *args = [[NSMutableArray alloc] init];
    id cursor = cdr;
    id selector = [cursor car];
    NSMutableString *selectorString = [NSMutableString stringWithString:[selector stringValue]];
    cursor = [cursor cdr];
    while (cursor && (cursor != [NSNull null])) {
        [args addObject:[[cursor car] evalWithContext:context]];
        cursor = [cursor cdr];
        if (cursor && (cursor != [NSNull null])) {
            [selectorString appendString:[[cursor car] stringValue]];
            cursor = [cursor cdr];
        }
    }
    SEL sel = sel_getUid([selectorString cStringUsingEncoding:NSUTF8StringEncoding]);
    
    // we're going to send the message to the handler of its superclass instead of one defined for its class.
    Class c = class_getSuperclass(_class);
    Method m = class_getInstanceMethod(c, sel);
    if (!m) m = class_getClassMethod(c, sel);
    
    id result;
    if (m) {
        result = nu_calling_objc_method_handler(_object, m, args);
    }
    else {
        NSLog(@"can't find function in superclass!");
        result = self;
    }
    [args release];
    return result;
}

@end

#pragma mark - NuSymbol.m

@interface NuSymbol (){
    NuSymbolTable *_table;
}
@property (nonatomic) bool isLabel;
@property (nonatomic) bool isGensym;// in macro evaluation, symbol is replaced with an automatically-generated unique symbol.
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, strong) id value;
@end

@interface NuSymbolTable ()
@property (nonatomic, strong) NSMutableDictionary *symbolTable;
@end

#define install(name, class) [(NuSymbol *) [symbolTable symbolWithString:name] setValue:[[[class alloc] init] autorelease]]
@implementation NuSymbolTable

+ (NuSymbolTable *) sharedSymbolTable{
    static NuSymbolTable *sharedSymbolTable = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSymbolTable = [[self alloc] init];
        [self loadBuiltIns:sharedSymbolTable];
    });
    return sharedSymbolTable;
}

+ (void) loadBuiltIns:(NuSymbolTable *) symbolTable{
    [(NuSymbol *) [symbolTable symbolWithString:@"t"] setValue:[symbolTable symbolWithString:@"t"]];
    [(NuSymbol *) [symbolTable symbolWithString:@"nil"] setValue:[NSNull NU_null]];
    [(NuSymbol *) [symbolTable symbolWithString:@"YES"] setValue:[NSNumber numberWithBool:YES]];
    [(NuSymbol *) [symbolTable symbolWithString:@"NO"] setValue:[NSNumber numberWithBool:NO]];
    
    install(@"car",      Nu_car_operator);
    install(@"cdr",      Nu_cdr_operator);
    install(@"first",    Nu_car_operator);
    install(@"rest",     Nu_cdr_operator);
    install(@"head",     Nu_car_operator);
    install(@"tail",     Nu_cdr_operator);
    install(@"atom",     Nu_atom_operator);
    install(@"defined",  Nu_defined_operator);
    
    install(@"eq",       Nu_eq_operator);
    install(@"eq?",      Nu_eq_operator);
    install(@"==",       Nu_eq_operator);
    install(@"ne",       Nu_neq_operator);
    install(@"ne?",      Nu_neq_operator);
    install(@"!=",       Nu_neq_operator);
    install(@"gt",       Nu_greaterthan_operator);
    install(@"gt?",      Nu_greaterthan_operator);
    install(@">",        Nu_greaterthan_operator);
    install(@"lt",       Nu_lessthan_operator);
    install(@"lt?",      Nu_lessthan_operator);
    install(@"<",        Nu_lessthan_operator);
    install(@"ge",       Nu_gte_operator);
    install(@"ge?",      Nu_gte_operator);
    install(@">=",       Nu_gte_operator);
    install(@"le",       Nu_lte_operator);
    install(@"le?",      Nu_lte_operator);
    install(@"<=",       Nu_lte_operator);
    
    install(@"cons",     Nu_cons_operator);
    install(@"append",   Nu_append_operator);
    install(@"apply",    Nu_apply_operator);
    
    install(@"cond",     Nu_cond_operator);
    install(@"case",     Nu_case_operator);
    install(@"if",       Nu_if_operator);
    install(@"unless",   Nu_unless_operator);
    install(@"while",    Nu_while_operator);
    install(@"until",    Nu_until_operator);
    install(@"for",      Nu_for_operator);
    install(@"break",    Nu_break_operator);
    install(@"continue", Nu_continue_operator);
    install(@"return",   Nu_return_operator);
    install(@"return-from",   Nu_return_from_operator);
    
    install(@"try",      Nu_try_operator);
    
    install(@"throw",    Nu_throw_operator);
    install(@"synchronized", Nu_synchronized_operator);
    
    install(@"quote",    Nu_quote_operator);
    install(@"eval",     Nu_eval_operator);
    
    install(@"context",  Nu_context_operator);
    install(@"set",      Nu_set_operator);
    install(@"global",   Nu_global_operator);
    install(@"local",    Nu_local_operator);
    
    install(@"regex",    Nu_regex_operator);
    
    install(@"function", Nu_function_operator);
    install(@"def",      Nu_function_operator);
    
    install(@"progn",    Nu_progn_operator);
    install(@"then",     Nu_progn_operator);
    install(@"else",     Nu_progn_operator);
    
    install(@"macro",    Nu_macro_1_operator);
    install(@"macrox",   Nu_macrox_operator);
    
    install(@"quasiquote",           Nu_quasiquote_operator);
    install(@"quasiquote-eval",      Nu_quasiquote_eval_operator);
    install(@"quasiquote-splice",    Nu_quasiquote_splice_operator);
    
    install(@"+",        Nu_add_operator);
    install(@"-",        Nu_subtract_operator);
    install(@"*",        Nu_multiply_operator);
    install(@"/",        Nu_divide_operator);
    install(@"**",       Nu_exponentiation_operator);
    install(@"%",        Nu_modulus_operator);
    
    install(@"&",        Nu_bitwiseand_operator);
    install(@"|",        Nu_bitwiseor_operator);
    install(@"<<",       Nu_leftshift_operator);
    install(@">>",       Nu_rightshift_operator);
    
    install(@"&&",       Nu_and_operator);
    install(@"||",       Nu_or_operator);
    
    install(@"and",      Nu_and_operator);
    install(@"or",       Nu_or_operator);
    install(@"not",      Nu_not_operator);
    
    install(@"min",      Nu_min_operator);
    install(@"max",      Nu_max_operator);
    
    install(@"list",     Nu_list_operator);
    
    install(@"do",       Nu_do_operator);
    
#if !TARGET_OS_IPHONE
    install(@"gets",     Nu_gets_operator);
#endif
    install(@"puts",     Nu_puts_operator);
    install(@"print",    Nu_print_operator);
    
    install(@"let",      Nu_let_operator);
    
    install(@"load",     Nu_load_operator);
    
    install(@"uname",    Nu_uname_operator);
    install(@"system",   Nu_system_operator);
    install(@"exit",     Nu_exit_operator);
    install(@"sleep",    Nu_sleep_operator);
    
    install(@"class",    Nu_class_operator);
    install(@"ivar",     Nu_ivar_operator);
    
    install(@"call",     Nu_call_operator);
    install(@"send",     Nu_send_operator);
    
    install(@"array",    Nu_array_operator);
    install(@"dict",     Nu_dict_operator);
    install(@"parse",    Nu_parse_operator);
    
    install(@"help",     Nu_help_operator);
    install(@"?",        Nu_help_operator);
    install(@"version",  Nu_version_operator);
    
    install(@"signature", Nu_signature_operator);
    
    // set some commonly-used globals
    [(NuSymbol *) [symbolTable symbolWithString:@"NSUTF8StringEncoding"]
     setValue:[NSNumber numberWithInt:NSUTF8StringEncoding]];
    
    [(NuSymbol *) [symbolTable symbolWithString:@"NSLog"] // let's make this an operator someday
     setValue:[NuBridgedFunction functionWithName:@"NSLog" signature:@"v@"]];
}

- (NSMutableDictionary *) symbolTable{
    if (_symbolTable == nil) {
        _symbolTable = [NSMutableDictionary new];
    }
    return _symbolTable;
}

- (void) dealloc{
    NSLog(@"WARNING: deleting a symbol table. Leaking stored symbols.");
    [super dealloc];
}

// Designated initializer
- (NuSymbol *) symbolWithString:(NSString *)string{
    // If the symbol is already in the table, return it.
    NuSymbol *symbol;
    symbol = [self.symbolTable objectForKey:string];
    if (symbol) return symbol;
    
    // If not, create it.
    symbol = [[[NuSymbol alloc] init] autorelease];             // keep construction private
    symbol.stringValue = string;
    
    const char *cstring = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSUInteger len = strlen(cstring);
    symbol.isLabel = (cstring[len - 1] == ':');
    symbol.isGensym = (len > 2) && (cstring[0] == '_') && (cstring[1] == '_');
    
    // Put the new symbol in the symbol table and return it.
    [self.symbolTable setObject:symbol forKey:string];
    return symbol;
}

- (NuSymbol *) lookup:(NSString *) string{
    return [self.symbolTable objectForKey:string];
}

- (NSArray *) all{
    return [self.symbolTable allValues];
}

- (void) removeSymbol:(NuSymbol *) symbol{
    [self.symbolTable removeObjectForKey:[symbol stringValue]];
}

@end



@implementation NuSymbol

- (void) dealloc{
    [_stringValue release];
    [super dealloc];
}

- (BOOL) isEqual: (NuSymbol *)other{
    return (self == other) ? 1l : 0l;
}

- (NSString *) description{
    return self.stringValue;
}

- (int) intValue{
    return (_value == [NSNull null]) ? 0 : 1;
}

- (NSString *) labelName{
    if (_isLabel)
        return [[self stringValue] substringToIndex:[[self stringValue] length] - 1];
    else
        return [self stringValue];
}

- (NSString *) labelValue{
    if (_isLabel)
        return [[self stringValue] substringToIndex:[[self stringValue] length] - 1];
    else
        return [self stringValue];
}

- (id) evalWithContext:(NSMutableDictionary *)context{
    
    char c = (char) [[self stringValue] characterAtIndex:0];
    // If the symbol is a class instance variable, find "self" and ask it for the ivar value.
    if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context lookupObjectForKey:[symbolTable symbolWithString:@"self"]];
        if (!object) return [NSNull null];
        id ivarName = [[self stringValue] substringFromIndex:1];
        id result = [object valueForIvar:ivarName];
        return result ? result : (id) [NSNull null];
    }
    
    // Next, try to find the symbol in the local evaluation context.
    id valueInContext = [context lookupObjectForKey:self];
    if (valueInContext)
        return valueInContext;
    
    // Next, return the global value assigned to the value.
    if (_value) return _value;
    
    // If the symbol is a label (ends in ':'), then it will evaluate to itself.
    if (_isLabel) return self;
    
    // If the symbol is still unknown, try to find a class with this name.
    id className = [self stringValue];
    // the symbol should retain its value.
    _value = [[NuClass classWithName:className] retain];
    if (_value) return _value;
    
    // Undefined globals evaluate to null.
    if (c == '$') return [NSNull null];
    
    // Now we try looking in the bridge support dictionaries.
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuSymbol *bridgeSupportSymbol = [symbolTable symbolWithString:@"BridgeSupport"];
    NSDictionary *bridgeSupport = bridgeSupportSymbol ? [bridgeSupportSymbol value] : nil;
    if (bridgeSupport) {
        // is it an enum?
        id enumValue = [[bridgeSupport valueForKey:@"enums"] valueForKey:[self stringValue]];
        if (enumValue) {
            _value = enumValue;
            return _value;
        }
        // is it a constant?
        id constantSignature = [[bridgeSupport valueForKey:@"constants"] valueForKey:[self stringValue]];
        if (constantSignature) {
            _value = [[NuBridgedConstant constantWithName:[self stringValue] signature:constantSignature] retain];
            return _value;
        }
        // is it a function?
        id functionSignature = [[bridgeSupport valueForKey:@"functions"] valueForKey:[self stringValue]];
        if (functionSignature) {
            _value = [[NuBridgedFunction functionWithName:[self stringValue] signature:functionSignature] retain];
            return _value;
        }
    }
    
    // Still-undefined symbols throw an exception.
    NSMutableString *errorDescription = [NSMutableString stringWithFormat:@"undefined symbol %@", [self stringValue]];
    id expression = [context lookupObjectForKey:[symbolTable symbolWithString:@"_expression"]];
    if (expression) {
        [errorDescription appendFormat:@" while evaluating expression %@", [expression stringValue]];
        const char *filename = nu_parsedFilename([expression file]);
        if (filename) {
            [errorDescription appendFormat:@" at %s:%d", filename, [expression line]];
        }
    }
    [NSException raise:@"NuUndefinedSymbol" format:@"%@", errorDescription];
    return [NSNull null];
}

- (NSComparisonResult) compare:(NuSymbol *) anotherSymbol{
    return [_stringValue compare:anotherSymbol->_stringValue];
}

- (id) copyWithZone:(NSZone *) zone{
    // Symbols are unique, so we don't copy them, but we retain them again since copies are automatically retained.
    return [self retain];
}

- (void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:[self stringValue]];
}

- (id) initWithCoder:(NSCoder *)coder{
    [super init];
    [self autorelease];
    return [[[NuSymbolTable sharedSymbolTable] symbolWithString:[coder decodeObject]] retain];
}

@end

#pragma mark - NuTestHelper.m

static BOOL verbose_helper = false;

@protocol NuTestProxy <NSObject>

- (CGRect) CGRectValue;
- (CGPoint) CGPointValue;
- (CGSize) CGSizeValue;
- (NSRange) NSRangeValue;

@end

@interface NuTestHelper : NSObject
@end

static int deallocationCount = 0;

@implementation NuTestHelper

+ (void) setVerbose:(BOOL) v{
    verbose_helper = v;
}

+ (BOOL) verbose{
    return verbose_helper;
}

+ (id) helperInObjCUsingAllocInit{
    id object = [[[NuTestHelper alloc] init] autorelease];
    return object;
}

+ (id) helperInObjCUsingNew{
    id object = [[NuTestHelper new] autorelease];
    return object;
}

- (void) dealloc{
    if (verbose_helper)
        NSLog(@"(NuTestHelper dealloc)");
    deallocationCount++;
    [super dealloc];
}

- (void) finalize{
    if (verbose_helper)
        NSLog(@"(NuTestHelper finalize %p)", self);
    deallocationCount++;
    [super finalize];
}

+ (void) resetDeallocationCount{
    deallocationCount = 0;
}

+ (int) deallocationCount{
    return deallocationCount;
}

+ (CGRect) getCGRectFromProxy:(id<NuTestProxy>) proxy {
    return [proxy CGRectValue];
}

+ (CGPoint) getCGPointFromProxy:(id<NuTestProxy>) proxy {
    return [proxy CGPointValue];
}

+ (CGSize) getCGSizeFromProxy:(id<NuTestProxy>) proxy {
    return [proxy CGSizeValue];
}

+ (NSRange) getNSRangeFromProxy:(id<NuTestProxy>) proxy {
    return [proxy NSRangeValue];
}

@end
