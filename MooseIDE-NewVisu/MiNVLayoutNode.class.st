Class {
	#name : #MiNVLayoutNode,
	#superclass : #MiNVAbstractNode,
	#instVars : [
		'children',
		'query'
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

{ #category : #initialization }
MiNVLayoutNode >> initialize [

	super initialize.
	children := OrderedCollection new
]

{ #category : #accessing }
MiNVLayoutNode >> query [

	^ query
]

{ #category : #accessing }
MiNVLayoutNode >> query: anObject [

	query := anObject
]
