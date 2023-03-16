Class {
	#name : #MiNVQueryNode,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'query',
		'result',
		'layout'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVQueryNode >> acceptVisitor: aVisitor [

	^ aVisitor visitQueryNode: self
]

{ #category : #testing }
MiNVQueryNode >> hasMultipleNodes [

	^ true
]

{ #category : #accessing }
MiNVQueryNode >> layout [

	^ layout
]

{ #category : #accessing }
MiNVQueryNode >> layout: anObject [

	layout := anObject
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
