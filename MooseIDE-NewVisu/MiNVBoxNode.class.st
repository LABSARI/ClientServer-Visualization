Class {
	#name : #MiNVBoxNode,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'layout',
		'name'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiNVBoxNode >> acceptVisitor: aVisitor [

	^ aVisitor visitBox: self
]

{ #category : #accessing }
MiNVBoxNode >> layout [

	^ layout
]

{ #category : #accessing }
MiNVBoxNode >> layout: anObject [

	layout := anObject
]

{ #category : #accessing }
MiNVBoxNode >> name [

	^ name
]

{ #category : #accessing }
MiNVBoxNode >> name: anObject [

	name := anObject
]
