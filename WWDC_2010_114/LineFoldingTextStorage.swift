/*
 File: LineFoldingTextStorage.swift
 Abstract: NSTextStorage subclass that adds NSAttachmentAttributeName for text with lineFoldingAttributeName.
 Version: 1.0

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2010 Apple Inc. All Rights Reserved.

 */

/// File created by Vlad Gorlov on 10.12.17 from file LineFoldingTextStorage.m

import Cocoa

private let sharedAttachment: NSTextAttachment = {
   let attachment = NSTextAttachment()
   attachment.attachmentCell = LineFoldingTextAttachmentCell(imageCell: nil)
   return attachment
}()

class LineFoldingTextStorage: NSTextStorage {

   @objc var lineFoldingEnabled = false
   private let attributedString = NSTextStorage()

   override var string: String {
      return attributedString.string
   }

   override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedStringKey : Any] {
      var attributes = attributedString.attributes(at: location, effectiveRange: range)
      if lineFoldingEnabled, let value = attributes[Constants.lineFoldingAttributeName] as? Bool, value == true {

         var effectiveRange = NSMakeRange(0, 0)
         attributedString.attribute(Constants.lineFoldingAttributeName, at: location,
                                    longestEffectiveRange: &effectiveRange, in: NSMakeRange(0, attributedString.length))
         // We adds NSAttachmentAttributeName if in lineFoldingAttributeName
         if location == effectiveRange.location { // beginning of a folded range
            attributes[.attachment] = sharedAttachment
            effectiveRange.length = 1
         } else {
            effectiveRange.location += 1
            effectiveRange.length -= 1
         }
         range?.pointee = effectiveRange
      }

      return attributes
   }

   override func replaceCharacters(in range: NSRange, with str: String) {
      attributedString.replaceCharacters(in: range, with: str)
      edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
   }

   override func setAttributes(_ attrs: [NSAttributedStringKey : Any]?, range: NSRange) {
      attributedString.setAttributes(attrs, range: range)
      edited(.editedAttributes, range: range, changeInLength: 0)
   }

   override func fixAttributes(in range: NSRange) {
      super.fixAttributes(in: range)
      enumerateAttribute(Constants.lineFoldingAttributeName, in: range, options: []) { value, nsRange, stop in
         if let range = Range<String.Index>(nsRange, in: string), value != nil && nsRange.length > 1 {
            var paragraphStart = String.Index(encodedOffset: 0)
            var paragraphEnd = String.Index(encodedOffset: 0)
            var contentsEnd = String.Index(encodedOffset: 0)
            string.getParagraphStart(&paragraphStart, end: &paragraphEnd, contentsEnd: &contentsEnd, for: range)
            if NSMaxRange(nsRange) == paragraphEnd.encodedOffset && contentsEnd < paragraphEnd {
               removeAttribute(Constants.lineFoldingAttributeName,
                               range: NSMakeRange(contentsEnd.encodedOffset, paragraphEnd.encodedOffset - contentsEnd.encodedOffset))
            }
         }
      }
   }
}
