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

	mapModel createLinksIn: visitHNodeCache.

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
		  addAll: (aPackageElement children collect: [ :c | 
					   self createAndStoreHNodeFor: c ]);
		  yourself
]

{ #category : #accessing }
MiLayerVisualizationBuilder >> highlightable [

	^ highlightable ifNil: [ 
		  highlightable := RSHighlightable new
			                   highlightShapes: [ :shape | 
				                   | list |
				                   list := shape connectedLines copy.
				                   list add: (shape propertyAt: #background).
				                   list ];
			                   when: RSHighlightEvent do: [ :evt | 
				                   evt shape isNode
					                   ifTrue: [ 
						                   highlightable
							                   record: evt shape
							                   selector: #border
							                   value: (RSBorder new
									                    color: (Color fromHexString: 'FF7F00');
									                    width: 3;
									                    yourself) ]
					                   ifFalse: [ 
					                   highlightable
						                   record: evt shape
						                   selector: #color
						                   value: Color red ] ]
			                   for: self;
			                   when: RSUnHighlightEvent do: [ :evt | 
				                   evt shape isNode
					                   ifTrue: [ 
					                   highlightable
						                   restore: evt shape
						                   selector: #border ]
					                   ifFalse: [ 
					                   highlightable
						                   restore: evt shape
						                   selector: #color ] ]
			                   for: self;
			                   yourself ]
]

{ #category : #accessing }
MiLayerVisualizationBuilder >> mapModel [

	^ mapModel
]

{ #category : #accessing }
MiLayerVisualizationBuilder >> mapModel: anObject [

	mapModel := anObject
]

{ #category : #building }
MiLayerVisualizationBuilder >> updateBuild [

	self container shapes do: #remove.
	description := mapModel buildDescription.
	self visit: description.
	mapModel createLinksIn: visitHNodeCache.
	self renderIn: self container.
	self container signalUpdate.
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
				          borderDashArray: #( 4 6 );
				          yourself);
		         color: Color transparent;
		         addAll:
		         (aMiNVBoxNode children collect: [ :c | 
			          c acceptVisitor: self ]);
		         yourself.
	aMiNVBoxNode expanded
		ifTrue: [ hNode expand ]
		ifFalse: [ hNode collapse ].
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
				   gapSize: aMiNVBoxNode gapSize;
				   alignMiddle;
				   yourself)
]

{ #category : #visiting }
MiLayerVisualizationBuilder >> visitPackageElement: aPackageElement [

	^ self createHNodeForPackage: aPackageElement
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
				   gapSize: aMiNVBoxNode gapSize;
				   alignCenter;
				   yourself)
]
