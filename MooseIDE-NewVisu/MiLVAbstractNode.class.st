Class {
	#name : #MiLVAbstractNode,
	#superclass : #Object,
	#instVars : [
		'expanded'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #visiting }
MiLVAbstractNode >> acceptVisitor: aVisitor [

	self subclassResponsibility
]

{ #category : #initialization }
MiLVAbstractNode >> collapse [

	expanded := false
]

{ #category : #initialization }
MiLVAbstractNode >> expand [

	expanded := true
]

{ #category : #initialization }
MiLVAbstractNode >> expanded [

	^ expanded
]

{ #category : #initialization }
MiLVAbstractNode >> initialize [

	super initialize.
	expanded := true.
]
