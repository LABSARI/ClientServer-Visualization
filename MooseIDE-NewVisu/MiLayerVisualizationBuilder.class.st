Class {
	#name : #MiLayerVisualizationBuilder,
	#superclass : #HSimpleVisualizationBuilder,
	#instVars : [
		'mapModel',
		'visitHNodeCache',
		'description'
	],
	#category : #'MooseIDE-NewVisu-Roassal-builder'
}

{ #category : #visiting }
MiLayerVisualizationBuilder >> addDependenciesTo: anHNode [

	| class |
	class := anHNode rawModel.
	(class allProviders collectAsSet: [ :p | mapModel rootClass: p ]) 
		do: [ :c | 
			visitHNodeCache
				at: c
				ifPresent: [ :node | anHNode dependencyTo: node ] ].
	(class allClients collectAsSet: [ :client | 
		 mapModel rootClass: client ]) do: [ :c | 
		visitHNodeCache
			at: c
			ifPresent: [ :node | node dependencyTo: anHNode ] ]
]

{ #category : #building }
MiLayerVisualizationBuilder >> addNextLevelButton [

	| next |
	
	next := RSLabel new
		        fontSize: 20;
		        text: 'Add level';
		        color: (Color fromHexString: '67001F');
		        yourself.

	next translateBy: 55 @ 15.
	self container add: next.
	
	next setAsFixed.
	
	next when: RSMouseClick do: [ 
		mapModel addLayer.
		self updateBuild ]
]

{ #category : #building }
MiLayerVisualizationBuilder >> build [

	mapModel initializePartitioning.

	self visit: mapModel buildDescription.

	self addNextLevelButton.

	self renderIn: self container.
	^ self container
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> changeColorFor: class [


	^ nil
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> createAndStoreHNodeFor: anLVElement [

	| hn |
	hn := self createHNodeFor: anLVElement.
	visitHNodeCache at: anLVElement model put: hn.
	self addDependenciesTo: hn.
	^ hn
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> createHNodeFor: anLVElement [

	| color class |
	class := anLVElement model.
	color := self changeColorFor: class.

	^ HNode new
		  name: anLVElement name;
		  rawModel: class;
		  color: (Color fromHexString: '80B1D3');
		  collapse;
		  yourself
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> createHNodeForPackage: aPackageElement [

	^ (self createHNodeFor: aPackageElement)
		  children:
			  (aPackageElement children collect: [ :c | self createAndStoreHNodeFor: c ]);
		  yourself
]

{ #category : #accessing }
MiLayerVisualizationBuilder >> mapModel [

	^ mapModel
]

{ #category : #accessing }
MiLayerVisualizationBuilder >> mapModel: anObject [

	mapModel := anObject
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> rsShapeFor: childrenNodes withRSLayout: aRoassalLayout [

	| group layoutChildrenNodes |
	layoutChildrenNodes := OrderedCollection new.
	group := RSGroup new.

	childrenNodes do: [ :c | group add: (c acceptVisitor: self) ].

	aRoassalLayout on: group.

	^ group asShape
]

{ #category : #building }
MiLayerVisualizationBuilder >> updateBuild [

	self container shapes do: #remove.
	description := mapModel buildDescription.
	self visit: description.

	self renderIn: self container.
	^ self container
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visit: aVisualizationModel [

	visitHNodeCache := Dictionary new.
	rootNode := aVisualizationModel acceptVisitor: self
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitBox: aMiNVBoxNode withRSLayout: aRoassalLayout [

	| hNode |
	hNode := HNode new
		         name: aMiNVBoxNode name;
		         layout: aRoassalLayout;
		         style: (HBorderAndTitleStyle new
				          borderDashArray: #( 5 10 );
				          yourself);
		         color: Color transparent;
		         children:
		         (aMiNVBoxNode children collect: [ :c | 
			          c acceptVisitor: self ]);
		         yourself.
	^ hNode
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitFlowBox: aMiNVBoxNode [

	^ self visitBox: aMiNVBoxNode withRSLayout: RSFlowLayout
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitHorizontalBox: aMiNVBoxNode [

	^ self
		  visitBox: aMiNVBoxNode
		  withRSLayout: (RSHorizontalLineLayout new
				   alignMiddle;
				   yourself)
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitPackageElement: aPackageElement [

	^ self createHNodeForPackage: aPackageElement
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitQueryNode: aMiNVQueryNode [

	| nodes group |
	nodes := aMiNVQueryNode query value collect: [ :i | 
		         HNode new
			         rawModel: i;
			         name: i name;
			         yourself ].
	group := nodes collect: [ :node | self shapeFor: node ] as: RSGroup.
	(self roassalLayout: aMiNVQueryNode layout) on: group.
	^ group asShape
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitTypeElement: aMiLVTypeElement [

	^ self createAndStoreHNodeFor: aMiLVTypeElement
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitVerticalBox: aMiNVBoxNode [

	^ self
		  visitBox: aMiNVBoxNode
		  withRSLayout: (RSVerticalLineLayout new
				   alignCenter;
				   yourself)
]
