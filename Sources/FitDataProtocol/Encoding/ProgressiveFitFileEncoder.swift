//
//  ProgressiveFitFileEncoder.swift
//  ProgressiveFitFileEncoder
//
//  Created by Joshua Levine on 10/3/21.
//

import Foundation

public class ProgressiveFitFileEncoder {
    let encoder: FitFileEncoder
    let fileType: FileType
    
    var lastDefinition: DefinitionMessage?
    
    public init(encoder: FitFileEncoder, fileType: FileType) {
        self.encoder = encoder
        self.fileType = fileType
    }
    
    public func encode(messages: [FitMessage]) -> Result<Data, FitEncodingError> {
        guard messages.count > 0 else {
            return .failure(FitEncodingError.noMessages)
        }
        
        var msgData = Data()
        
        for message in messages {
            /// Endocde the Definition
            let def = message.encodeDefinitionMessage(fileType: fileType, dataValidityStrategy: encoder.dataValidityStrategy)
            switch def {
            case .success(let definition):
                if lastDefinition == nil || lastDefinition! != definition {
                    lastDefinition = definition
                    msgData.append(encoder.encodeDefHeader(index: 0, definition: lastDefinition!))
                }
                
            case .failure(let error):
                return .failure(error)
            }

            /// Endode the Message
            switch message.encode(localMessageType: 0, definition: lastDefinition!) {
            case .success(let data):
                msgData.append(data)
            case .failure(let error):
                return .failure(error)
            }
        }

        if msgData.count > UInt32.max {
            return .failure(FitEncodingError.tooManyMessages)
        }
        
        return .success(msgData)
    }
}
