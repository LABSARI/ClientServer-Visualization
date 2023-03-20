Class {
	#name : #MiLVQueryNode,
	#superclass : #MiLVAbstractNode,
	#instVars : [
		'query',
		'result',
		'layout'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVQueryNode >> acceptVisitor: aVisitor [

	^ aVisitor visitQueryNode: self
]

{ #category : #testing }
MiLVQueryNode >> hasMultipleNodes [

	^ true
]

{ #category : #accessing }
MiLVQueryNode >> layout [

	^ layout
]

{ #category : #accessing }
MiLVQueryNode >> layout: anObject [

	layout := anObject
]

{ #category : #accessing }
MiLVQueryNode >> query [

	^ query
]

{ #category : #accessing }
MiLVQueryNode >> query: anObject [

	query := anObject
]

{ #category : #accessing }
MiLVQueryNode >> result [

	^ result
]

{ #category : #accessing }
MiLVQueryNode >> result: anObject [

	result := anObject
]
