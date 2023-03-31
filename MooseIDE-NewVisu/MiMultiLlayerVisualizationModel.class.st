Class {
	#name : #MiMultiLlayerVisualizationModel,
	#superclass : #MiLayerVisualizationModel,
	#instVars : [
		'daoTag',
		'implAndIntViolation',
		'serviceTag',
		'serviceLayer',
		'daoLayer'
	],
	#category : #'MooseIDE-NewVisu-Model'
}

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addDependenciesFrom: sourcesLayer to: targetsLayer execute: aBlock [

	sourcesLayer do: [ :class | 
		(self classDependenciesFor: class) do: [ :dc | 
			(targetsLayer includes: dc) ifTrue: [ :target | 
				self addDependency: dc in: incomingCache for: class.
				self addDependency: class in: outgoingCache for: dc.
				aBlock value: class value: dc ] ] ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addDependenciesToDaoAndTag [

	self
		addDependenciesFrom: (self serverLayers at: 1)
		to: daoLayer
		execute: [ :impl :dao | 
			dao tagWith: daoTag.
			impl tagWith: implAndIntViolation ].

	daoLayer do: [ :class | 
		(self classDependenciesFor: class) do: [ :d | 
			(serviceLayer includes: d) ifTrue: [ 
				self addDependency: d in: incomingCache for: class.
				self addDependency: class in: outgoingCache for: d ] ] ].


	serviceLayer do: [ :class | 
		(self classDependenciesFor: class) do: [ :d | 
			((self serverLayers at: 1) includes: d) ifTrue: [ 
				self addDependency: d in: incomingCache for: class.
				self addDependency: class in: outgoingCache for: d ] ] ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> addDependenciesToServicesAndTag [

	self
		addDependenciesFrom: (self serverLayers at: 1)
		to: serviceLayer
		execute: [ :impl :service | 
			(service hasTag: serviceTag) ifFalse: [ 
				service tagWith: serviceTag ] ]
]

{ #category : #queries }
MiMultiLlayerVisualizationModel >> dao [

	| sa |
	sa := (((FQStringQuery
		         property: #name
		         comparator: #=
		         valueToCompare: 'DaoAbstract') runOn:
		        self services anyOne rawModel mooseModel allClasses) 
		       reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.

	^ sa subclassHierarchy collect: [ :s | self buildNodeFromEntity: s ]
]

{ #category : #queries }
MiMultiLlayerVisualizationModel >> eServices [

	| sa |
	sa := (((FQStringQuery
		         property: #name
		         comparator: #=
		         valueToCompare: 'ServiceAbstract') runOn:
		        self services anyOne rawModel mooseModel allClasses) 
		       reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.

	^ sa subclassHierarchy collect: [ :s | self buildNodeFromEntity: s ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> initializeOtherLayers [

	daoTag := (self mooseModel tagNamed: 'daoViolation')
		          color: (Color fromHexString: 'B2182B');
		          yourself.
	implAndIntViolation := (self mooseModel tagNamed: 'implAndIntViolation').
	serviceTag := (self mooseModel tagNamed: 'serviceNoViolation')
		              color: (Color fromHexString: 'EF8A62');
		              yourself. 
	self eServices do: [ :c | serviceLayer at: c rawModel put: c ].
	self dao do: [ :c | daoLayer at: c rawModel put: c ]
]

{ #category : #adding }
MiMultiLlayerVisualizationModel >> initializePartitioning [

	super initializePartitioning.
	self initializeOtherLayers.

	self addDependenciesToDaoAndTag.
	self addDependenciesToServicesAndTag
]
