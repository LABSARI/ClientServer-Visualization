Class {
	#name : #MiNVQueryNode,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'query',
		'result'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #visiting }
MiNVQueryNode >> acceptVisitor: aVisitor [

	^ aVisitor visitQueryNode: self
]

{ #category : #accessing }
MiNVQueryNode >> query [

	^ query
]

{ #category : #accessing }
MiNVQueryNode >> query: anObject [

	query := anObject
]

{ #category : #accessing }
MiNVQueryNode >> result [

	^ result
]

{ #category : #accessing }
MiNVQueryNode >> result: anObject [

	result := anObject
]
