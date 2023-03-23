Class {
	#name : #MiAbstractDisplayStrategy,
	#superclass : #Object,
	#instVars : [
		'visualizationModel'
	],
	#category : #'MooseIDE-NewVisu-Strategy'
}

{ #category : #filtering }
MiAbstractDisplayStrategy >> addDto: dto in: dict atKey: aSymbol [

	^ dict at: aSymbol ifPresent: [ :coll | coll add: dto ]
]

{ #category : #filtering }
MiAbstractDisplayStrategy >> fetchNotSharedDTOs [

	self subclassResponsibility
]

{ #category : #filtering }
MiAbstractDisplayStrategy >> fetchViolatingEntities [

	self subclassResponsibility
]

{ #category : #accessing }
MiAbstractDisplayStrategy >> visualizationModel [

	^ visualizationModel
]

{ #category : #accessing }
MiAbstractDisplayStrategy >> visualizationModel: anObject [

	visualizationModel := anObject
]
