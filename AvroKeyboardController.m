//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AvroKeyboardController.h"
#import "Suggestion.h"
#import "Candidates.h"
#import "CacheManager.h"
#import "RegexKitLite.h"
#import "AvroParser.h"
#import "AutoCorrect.h"

@implementation AvroKeyboardController

@synthesize prefix = _prefix, term = _term, suffix = _suffix;

- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)inputClient {
    
    self = [super initWithServer:server delegate:delegate client:inputClient];
    
	if (self) {
        _selectedIndex = 0;
        _composedBuffer = [[NSMutableString alloc] initWithString:@""];
        _currentCandidates = [[NSMutableArray alloc] initWithCapacity:0];
        _prevSelected = -1;
    }

	return self;
}

- (void)dealloc {
    [_prefix release];
    [_term release];
    [_suffix release];
    [_currentCandidates release];
    [_composedBuffer release];
	[super dealloc];
}

- (void)findCurrentCandidates {
    [_currentCandidates removeAllObjects];
    _prevSelected = -1;
    _selectedIndex = 0;
    if (_composedBuffer && [_composedBuffer length] > 0) {
        NSString* regex = @"(^(?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*?(?=(?:,{2,}))|^(?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*)(.*?(?:,,)*)((?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*$)";
        NSArray* items = [_composedBuffer captureComponentsMatchedByRegex:regex];
        if (items && [items count] > 0) {
            // Split Prefix, Term & Suffix
            [self setPrefix:[[AvroParser sharedInstance] parse:[items objectAtIndex:1]]];
            [self setTerm:[items objectAtIndex:2]];
            [self setSuffix:[[AvroParser sharedInstance] parse:[items objectAtIndex:3]]];
            
            NSArray* found = [[Suggestion sharedInstance] getList:[self term]];
            [_currentCandidates release];
            _currentCandidates = [[NSMutableArray alloc] initWithArray:found];
            [[Suggestion sharedInstance] clearList];
            if (_currentCandidates && [_currentCandidates count] > 0) {
                NSString* prevString = nil;
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
                    _prevSelected = -1;
                    prevString = [[CacheManager sharedInstance] stringForKey:[self term]];
                }
                int i;
                for (i = 0; i < [_currentCandidates count]; ++i) {
                    NSString* item = [_currentCandidates objectAtIndex:i];
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"] && 
                        _prevSelected && [item isEqualToString:prevString] ) {
                        _prevSelected = i;
                    }
                    [_currentCandidates replaceObjectAtIndex:i withObject:
                     [NSString stringWithFormat:@"%@%@%@", [self prefix], item, [self suffix]]];
                }
                // Emoticons                
                if ([_composedBuffer isEqualToString:[self term]] == NO && 
                    [[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
                    NSString* smily = [[AutoCorrect sharedInstance] find:_composedBuffer];
                    if (smily) {
                        [_currentCandidates insertObject:smily atIndex:0];
                    }
                }
            }
            else {
                [_currentCandidates addObject:[self prefix]];
            }
            if (_prevSelected > -1) {
                _selectedIndex = _prevSelected;
            }
        }
    }
    if ([_currentCandidates count] == 0 && [_composedBuffer length] > 0) {
        [_currentCandidates addObject:[NSString stringWithString:_composedBuffer]];
    }
}

- (void)updateCandidatesPanel {
    if (_currentCandidates && [_currentCandidates count] > 0) {
        NSUserDefaults *defaultsDictionary = [NSUserDefaults standardUserDefaults];
        
        // NSString *candidateFontName = [defaultsDictionary objectForKey:@"candidateFontName"];
        // float candidateFontSize = [[defaultsDictionary objectForKey:@"candidateFontSize"] floatValue];
        
        // NSFont *candidateFont = [NSFont fontWithName:candidateFontName size:candidateFontSize];
        // [[Candidates sharedInstance] setAttributes:[NSDictionary dictionaryWithObject:candidateFont forKey:NSFontAttributeName]];
        
        [[Candidates sharedInstance] setPanelType:[defaultsDictionary integerForKey:@"CandidatePanelType"]];
        [[Candidates sharedInstance] updateCandidates];
        [[Candidates sharedInstance] show:kIMKLocateCandidatesBelowHint];
        if (_prevSelected > -1) {
            [[Candidates sharedInstance] selectCandidate:_prevSelected];
        }
    }
    else {
        [[Candidates sharedInstance] hide];
    }
}

- (NSArray*)candidates:(id)sender {
	return _currentCandidates;	
}

- (void)candidateSelectionChanged:(NSAttributedString*)candidateString {
    NSUInteger idx = [_currentCandidates indexOfObject:[candidateString string]];
    if (idx != NSNotFound) {
        _selectedIndex = (NSInteger)idx;
    }
    if ([_currentCandidates count] == 0) {
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
        if ([self term] && [[self term] length] > 0) {
            BOOL comp = [[candidateString string] isEqualToString:[_currentCandidates objectAtIndex:0]];
            if ((comp && _prevSelected == -1) == NO) {
                NSRange range = NSMakeRange([[self prefix] length], 
                                            [candidateString length] - ([[self prefix] length] + [[self suffix] length]));
                [[CacheManager sharedInstance] setString:[[candidateString string] substringWithRange:range] forKey:[self term]];
                
                // Reverse Suffix Caching
                NSArray* tmpArray = [[CacheManager sharedInstance] baseForKey:[candidateString string]];
                if (tmpArray && [tmpArray count] > 0) {
                    [[CacheManager sharedInstance] setString:[tmpArray objectAtIndex:1] forKey:[tmpArray objectAtIndex:0]];
                }
            }
        }
    }
}

- (NSString*)currentChoice {
    if ([_currentCandidates count] == 0) {
        return _composedBuffer.length ? [NSString stringWithString:_composedBuffer] : nil;
    }
    if (_selectedIndex < 0 || _selectedIndex >= (NSInteger)[_currentCandidates count]) {
        _selectedIndex = 0;
    }
    return [_currentCandidates objectAtIndex:_selectedIndex];
}

- (void)commitString:(NSString*)string {
    id client = [self client];
    if (string && [string length] > 0 && client) {
        [client insertText:string replacementRange:NSMakeRange(NSNotFound, 0)];
    }
    [self clearCompositionBuffer];
    [_currentCandidates removeAllObjects];
    _selectedIndex = 0;
    [self setPrefix:nil];
    [self setTerm:nil];
    [self setSuffix:nil];
    [[Candidates sharedInstance] hide];
}

- (void)candidateSelected:(NSAttributedString*)candidateString {
    [self commitString:[candidateString string]];
}

- (void)commitComposition:(id)sender {
    [self commitString:[self currentChoice]];
}

- (void)activateServer:(id)sender {
    [super activateServer:sender];
}

- (void)deactivateServer:(id)sender {
    if ([_composedBuffer length] > 0) {
        [self commitString:[self currentChoice]];
    }
    [[Candidates sharedInstance] hide];
    [super deactivateServer:sender];
}

- (id)composedString:(id)sender {
	return [[[NSAttributedString alloc] initWithString:_composedBuffer] autorelease];
}

- (void)clearCompositionBuffer {
	[_composedBuffer deleteCharactersInRange:NSMakeRange(0, [_composedBuffer length])];	
}

/*
 Implement one of the three ways to receive input from the client. 
 Here are the three approaches:
 
 1.  Support keybinding.  
 In this approach the system takes each keydown and trys to map the keydown to an action method that the input method has implemented.  If an action is found the system calls didCommandBySelector:client:.  If no action method is found inputText:client: is called.  An input method choosing this approach should implement
 -(BOOL)inputText:(NSString*)string client:(id)sender;
 -(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender;
 
 2. Receive all key events without the keybinding, but do "unpack" the relevant text data.
 Key events are broken down into the Unicodes, the key code that generated them, and modifier flags.  This data is then sent to the input method's inputText:key:modifiers:client: method.  For this approach implement:
 -(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender;
 
 3. Receive events directly from the Text Services Manager as NSEvent objects.  For this approach implement:
 -(BOOL)handleEvent:(NSEvent*)event client:(id)sender;
 */

/*!
 @method     
 @abstract   Receive incoming text.
 @discussion This method receives key board input from the client application.  The method receives the key input as an NSString. The string will have been created from the keydown event by the InputMethodKit.
 */
- (BOOL)inputText:(NSString*)string client:(id)sender {
    if ([string length] == 0) {
        return NO;
    }
    unichar c = [string characterAtIndex:0];
    if (c == ' ') {
        if ([_composedBuffer length] > 0) {
            // Commit the chosen Bangla word and the space ourselves; never leave the word uncommitted.
            NSString* choice = [self currentChoice];
            [self commitString:[choice stringByAppendingString:@" "]];
            return YES;
        }
        return NO;
    }
    if (c < 0x20 || c == 0x7F) {
        return NO;
    }
    [_composedBuffer appendString:string];
    [self findCurrentCandidates];
    [self updateComposition];
    [self updateCandidatesPanel];
    return YES;
}

- (void)deleteBackward:(id)sender {
    // We're called only when [compositionBuffer length] > 0
    if ([_composedBuffer length] == 0) {
        return;
    }
    [_composedBuffer deleteCharactersInRange:NSMakeRange([_composedBuffer length] - 1, 1)];
    [self findCurrentCandidates];
    [self updateComposition];
    [self updateCandidatesPanel];
}

- (void)insertTab:(id)sender {
    [self commitText:@"\t"];
}

- (void)insertNewline:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CommitNewLineOnEnter"]) {
        [self commitText:@"\n"];
    }
    else {
        [self commitText:@""];
    }
}

- (void)cancelOperation:(id)sender {
    // Esc: drop the Bangla suggestion and keep what was typed
    NSString* raw = [NSString stringWithString:_composedBuffer];
    [self commitString:raw];
}

- (void)moveCandidate:(NSInteger)delta {
    NSInteger n = (NSInteger)[_currentCandidates count];
    if (n == 0) return;
    _selectedIndex = (_selectedIndex + delta + n) % n;
    [[Candidates sharedInstance] selectCandidate:(int)_selectedIndex];
}

- (BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
    if ([_composedBuffer length] == 0) {
        return NO;
    }
    if (aSelector == @selector(insertTab:)
        || aSelector == @selector(insertNewline:)
        || aSelector == @selector(deleteBackward:)
        || aSelector == @selector(cancelOperation:)) {
        [self performSelector:aSelector withObject:sender];
        return YES;
    }
    if (aSelector == @selector(moveDown:) || aSelector == @selector(moveRight:)) {
        [self moveCandidate:1];
        return YES;
    }
    if (aSelector == @selector(moveUp:) || aSelector == @selector(moveLeft:)) {
        [self moveCandidate:-1];
        return YES;
    }
    return NO;
}

- (void)commitText:(NSString*)string {
    NSString* choice = [self currentChoice];
    [self commitString:[(choice ? choice : @"") stringByAppendingString:string]];
}

- (NSMenu*)menu {
    return [[NSApp delegate] menu];
}

@end