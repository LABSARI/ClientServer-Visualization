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

	(mapModel purgatoryLayer includes: anHNode rawModel) ifFalse: [ 
		^ self ].
	mapModel incomingCache at: anHNode rawModel ifPresent: [ :c | 
		c do: [ :i | 
			visitHNodeCache
				at: i
				ifPresent: [ :node | node dependencyTo: anHNode ] ] ].
	mapModel outgoingCache at: anHNode rawModel ifPresent: [ :c | 
		c do: [ :i | 
			visitHNodeCache
				at: i
				ifPresent: [ :node | anHNode dependencyTo: node ] ] ]
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

		self updateBuild]
]

{ #category : #building }
MiLayerVisualizationBuilder >> borderForSet [

	^ RSBorder new
		  width: 3;
		  capSquare;
		  joinMiter;
		  color: Smalltalk ui theme textColor;
		  dashArray: #(5 10);
		  yourself
]

{ #category : #building }
MiLayerVisualizationBuilder >> build [

	mapModel initializePartitioning.

	self visit: mapModel buildDescription.

	self addNextLevelButton.

	self renderLinesIn: self container.
	self container @ self menuInteraction
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
		  color: color;
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

{ #category : #building }
MiLayerVisualizationBuilder >> labelFromString: aString [

	^ RSComposite new
		  add: (RSLabel new
				   text: aString;
				   fontSize: 25;
				   color: Color black;
				   yourself);
		  adjustToChildren;
		  padding: 10 @ 0;
		  color: Color transparent;
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
MiLayerVisualizationBuilder >> roassalBorderFor: aSymbol [

	aSymbol = #dashed ifTrue: [ ^ self borderForSet ].
	aSymbol = #line ifTrue: [ ^ nil ].
	aSymbol = #without ifTrue: [ ^ nil ]
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
"	rootNode hideAllLinks."
	self renderLinesIn: self container.
	self container signalUpdate
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visit: aVisualizationModel [

	| rootShape |
	shapes := OrderedCollection new.
	rootNode := HNode new.
	visitHNodeCache := Dictionary new.
	rootShape := aVisualizationModel acceptVisitor: self.
	self container add: rootShape.
	self container schildren: shapes
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitBox: aMiNVBoxNode withRSLayout: aRoassalLayout [

	| shape label |
	label := self labelFromString: aMiNVBoxNode name.

	shape := RSComposite new.

	shape add:
		(self rsShapeFor: aMiNVBoxNode children withRSLayout: aRoassalLayout).

	shape
		adjustToChildren;
		border: (self roassalBorderFor: aMiNVBoxNode borderStyle);
		padding: 50;
		color: aMiNVBoxNode backgroundColor.
	shape add: label.

	RSLocation new
		left;
		top;
		inner;
		move: label on: shape baseRectangle.
	^ shape
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

	| hNode shape |
	hNode := self createHNodeForPackage: aPackageElement.
	rootNode add: hNode.
	shape := (self shapeFor: hNode)
		         sparent: self container;
		         yourself.
	shapes add: shape.
	^ shape
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

	| hNode shape |
	hNode := self createAndStoreHNodeFor: aMiLVTypeElement.
	rootNode add: hNode.
	shape := (self shapeFor: hNode)
		         sparent: self container;
		         yourself.
	shapes add: shape.
	^ shape
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitVerticalBox: aMiNVBoxNode [

	^ self
		  visitBox: aMiNVBoxNode
		  withRSLayout: (RSVerticalLineLayout new
				   alignCenter;
				   yourself)
]
