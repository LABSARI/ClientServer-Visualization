Class {
	#name : #MiNVLayoutNode,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'children',
		'query',
		'gapSize'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #initialization }
MiNVLayoutNode >> add: aNVNode [

	children add: aNVNode
]

{ #category : #initialization }
MiNVLayoutNode >> addAll: aCollection [

	children addAll: aCollection
]

{ #category : #initialization }
MiNVLayoutNode >> children [

	^ children
]

{ #category : #accessing }
MiNVLayoutNode >> gapSize [

	^ gapSize
]

{ #category : #accessing }
MiNVLayoutNode >> gapSize: anObject [

	gapSize := anObject
]

{ #category : #initialization }
MiNVLayoutNode >> initialize [

	super initialize.
	children := OrderedCollection new.
	gapSize := 3
]

{ #category : #accessing }
MiNVLayoutNode >> query [

	^ query
]

{ #category : #accessing }
MiNVLayoutNode >> query: anObject [

	query := anObject
]
