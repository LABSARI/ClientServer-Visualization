Class {
	#name : #MiNewVisuBuilder,
	#superclass : #HSimpleVisualizationBuilder,
	#instVars : [
		'mapModel',
		'highlightShapes',
		'spackageDict',
		'cpackageDict',
		'pNodes',
		'continueClient',
		'continueServer',
		'index',
		'description'
	],
	#category : #'MooseIDE-NewVisu-Roassal-builder'
}

{ #category : #building }
MiNewVisuBuilder >> addNextLevelButton [

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
MiNewVisuBuilder >> borderForSet [

	^ RSBorder new
		  width: 3;
		  capSquare;
		  joinMiter;
		  color: Smalltalk ui theme textColor;
		  dashArray: #(5 10);
		  yourself
]

{ #category : #building }
MiNewVisuBuilder >> boxChildrenColorFor: anHNode [

	^ Color fromHexString: 'CCCCCC'
]

{ #category : #building }
MiNewVisuBuilder >> build [

	mapModel initializePartitioning.
	
	description := mapModel buildFirstDescription.

	self visit: description.

	self addNextLevelButton.

	self renderLinesIn: self container.
	self container @ self menuInteraction
]

{ #category : #building }
MiNewVisuBuilder >> buildCompositeEmptyNodeIn: shape [

	| node box rect |
	node := shape model.
	shape addAll: (self nodeStyler labelAndIconFor: node).
	rect := shape children encompassingRectangle.
	box := RSBox new
		       model: node;
		       position: rect floatCenter;
		       extent: rect extent + 10;
		       cornerRadius: self fullCornerRadius;
		       color: (self colorFor: node);
		       border: (self borderFor: node);
		       yourself.
	shape color: (self colorFor: node).
	shape add: box.
	box pushBack.
	shape schildren: #(  ).

	shape
		propertyAt: #background put: box;
		adjustToChildren
]

{ #category : #building }
MiNewVisuBuilder >> buildDescription [

	| serverLayouts clientLayouts sharedGroups  |
	"L"
	serverLayouts := self buildLayoutsFor: mapModel serverLayers reversed: false.
	clientLayouts := self buildLayoutsFor: mapModel clientLayers reversed: true.
	
	sharedGroups := mapModel sharedLayer values groupedBy: [ :n | 
		                (n rawModel superclassHierarchy anySatisfy: [ :sc | 
			                 sc name = 'BaseModel' or: [ 
				                 sc name = 'BaseModelData' ] ])
			                ifTrue: [ #dto ]
			                ifFalse: [ 
				                (n rawModel usesFamixTrait: FamixTEnum)
					                ifTrue: [ #enum ]
					                ifFalse: [ #other ] ] ].
	sharedGroups at: #enum ifAbsentPut: [ OrderedCollection new ].
	sharedGroups at: #other ifAbsentPut: [ OrderedCollection new ].
	sharedGroups at: #dto ifAbsentPut: [ OrderedCollection new ].

	(description := MiLVVerticalLayoutNode new)
		gapSize: 90;
		add: (MiLVAbstractBoxNode new
				 name: 'Shared';
				 layout: (MiLVFlowLayoutNode new
						  gapSize: 80;
						  add: (MiLVAbstractBoxNode new
								   name:
									   'DTOs: ' , (sharedGroups at: #dto) size asString
									   , ' classes';
								   layout: (MiLVFlowLayoutNode new
										    gapSize: 80;
										    addAll:
											    ((self commonPackagesFor: (sharedGroups at: #dto)) 
												     collect: [ :c | 
													     MiLVAbstractElement new
														     model: c;
														     yourself ]);
										    yourself);
								   yourself);
						  add: (MiLVAbstractBoxNode new
								   name:
									   'Enums: ' , (sharedGroups at: #enum) size asString
									   , ' classes';
								   layout: (MiLVFlowLayoutNode new
										    gapSize: 80;
										    addAll:
											    ((self commonPackagesFor: (sharedGroups at: #enum)) 
												     collect: [ :c | 
													     MiLVAbstractElement new
														     model: c;
														     yourself ]);
										    yourself);
								   yourself);
						  yourself);
				 yourself);
		add: (MiLVHorizontalLayoutNode new
				 gapSize: 90;
				 add: (MiLVAbstractBoxNode new
						  name: 'Client';
						  layout: (MiLVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: clientLayouts;
								   yourself);
						  yourself);
				 add: (MiLVAbstractBoxNode new
						  name: 'Server';
						  layout: (MiLVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: serverLayouts;
								   yourself);
						  yourself);
				 yourself);
		add: (MiLVAbstractBoxNode new
				 name: 'Purgatory: ', (mapModel purgatoryLayer values) size asString, ' classes';
				 layout: (MiLVFlowLayoutNode new
						  addAll:
							  ((self commonPackagesFor: (mapModel purgatoryLayer values))
								   collect: [ :c | 
									   MiLVAbstractElement new
										   model: c;
										   yourself ]);
						  yourself);
				 yourself).
	^ description
]

{ #category : #building }
MiNewVisuBuilder >> buildLayoutsFor: dicts reversed: reverse [

	| layouts |
	layouts := dicts withIndexCollect: [ :d :i | 
		           | box layout entities filtered |
		           i = 1
			           ifTrue: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.

				           layout := MiLVVerticalLayoutNode new.
				           box := MiLVAbstractBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself.
				           entities := filtered sort: [ :a :b | a name < b name ] ]
			           ifFalse: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.
				           layout := MiLVFlowLayoutNode new.
				           entities := self commonPackagesFor: filtered.
				           box := MiLVAbstractBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself ].
		           layout addAll: (entities collect: [ :c | 
				            MiLVAbstractElement new
					            model: c;
					            yourself ]).
		           box ].
	^ reverse
		  ifTrue: [ layouts reversed ]
		  ifFalse: [ layouts ]
]

{ #category : #building }
MiNewVisuBuilder >> buildNodeFromEntity: anEntity [

	| node |
	node := HNode new
		        name:
			        (String streamContents: [ :s | anEntity displayStringOn: s ]);
		        rawModel: anEntity;
		        iconName: #class;
		        collapse;
		        yourself.
	^ node
]

{ #category : #building }
MiNewVisuBuilder >> colorFor: node [

	| entity |
	node color ifNotNil: [ :c | ^ c ].
	entity := node rawModel.

	(entity isType and: [ 
		 (mapModel sharedLayer includes: entity) and: [ 
			 self nodeIsShared: node ] ]) ifTrue: [ 
		^ Color fromHexString: '9970AB' ].

	(entity isPackage and: [ 
		 (mapModel sharedLayer includes: node children anyOne rawModel) 
			 and: [ 
			 node children anySatisfy: [ :child | self nodeIsShared: child ] ] ]) 
		ifTrue: [ ^ Color fromHexString: '9970AB' ].

	(entity isPackage and: [ self packagePresentInBothSides: entity ]) 
		ifTrue: [ ^ Color fromHexString: 'DFC27D' ].


	"mapModel shouldColor ifFalse: [ ^ Color fromHexString: '7FC6F6' ].

	^ (self entityIsInClientPackage: entity)
		  ifTrue: [ Color fromHexString: '7FC6F6' ]
		  ifFalse: [ Color fromHexString: 'FFABA3' ]"
	^ Color fromHexString: 'D1E5F0'
]

{ #category : #building }
MiNewVisuBuilder >> commonPackagesFor: classes [

	| groups dict r |
	self flag: 'to modify'.
	classes ifEmpty: [ ^ OrderedCollection new ].
	r := self classAlreadyPresent: classes anyOne rawModel.
	r = #client ifTrue: [ dict := cpackageDict ].
	r = #server ifTrue: [ dict := spackageDict ].
	groups := (classes groupedBy: [ :c | 
		           (c rawModel atScope: FamixTPackage) anyOne ])
		          associations.
	^ (groups collect: [ :a | 
		   dict ifNotNil: [ dict at: a key ifAbsentPut: a key ].
		   (self buildNodeFromEntity: a key)
			   addAll: a value;
			   iconName: #package;
			   yourself ]) sorted: [ :a :b | a name < b name ]
]

{ #category : #visiting }
MiNewVisuBuilder >> createHNodeFor: anLVElement [

	^ HNode new
		  name: anLVElement name;
		  rawModel: anLVElement model;
		  collapse;
		  yourself
]

{ #category : #visiting }
MiNewVisuBuilder >> createHNodeForPackage: aPackageElement [

	^ (self createHNodeFor: aPackageElement)
		  children:
			  (aPackageElement children collect: [ :c | self createHNodeFor: c ]);
		  yourself
]

{ #category : #accessing }
MiNewVisuBuilder >> elements [

	| entities |
	entities := OrderedCollection new.
	entities addAll:
		(mapModel entities sort: [ :a :b | a name < b name ]).

	^ entities collect: [ :e | self buildNodeFromEntity: e ]
]

{ #category : #building }
MiNewVisuBuilder >> entitiesWithViolationFrom: aDict [

	^ aDict values
]

{ #category : #building }
MiNewVisuBuilder >> highlightable [

	^ highlightable ifNil: [ 
		  highlightable := RSHighlightable new
			                   highlightShapes: [ :shape | 
				                   | list |
				                   list := shape connectedLines copy.
				                   list add: (shape propertyAt: #background).
				                   list ];
			                   when: RSHighlightEvent do: [ :evt | 
				                   | color |
				                 
				                   color := evt shape isNode
					                            ifTrue: [ evt shape color muchDarker ]
					                            ifFalse: [ 
						                            evt source = evt shape from
							                            ifTrue: [ Color red ]
							                            ifFalse: [ Color blue ] ].
				                   highlightable
					                   record: evt shape
					                   selector: #color
					                   value: color ];
			                   when: RSUnHighlightEvent
			                   do: [ :evt | 
				                   highlightable
					                   restore: evt shape
					                   selector: #color ];
			                   yourself ]
]

{ #category : #building }
MiNewVisuBuilder >> highlightableLinkedShapes [

	^ highlightShapes ifNil: [ 
		  highlightShapes := RSHighlightable new
			                     highlightShapes: [ :shape | 
				                     | list |
				                     list := Set new.
				                     shape connectedLines do: [ :line | 
						                     shape = line from
							                     ifTrue: [ 
								                     list add:
										                     (line to propertyAt: #background) ]
							                     ifFalse: [ 
								                     list add:
										                     (line from propertyAt: #background) ] ].
				                     list asOrderedCollection ];
			                     when: RSHighlightEvent do: [ :evt | 
				                     | color |
				                     color := Color fromHexString: '9DD0B3'.
				                     highlightable
					                     record: evt shape
					                     selector: #color
					                     value: color ];
			                     when: RSUnHighlightEvent
			                     do: [ :evt | 
				                     highlightable
					                     restore: evt shape
					                     selector: #color ];
			                     yourself ]
]

{ #category : #initialization }
MiNewVisuBuilder >> initialize [

	super initialize.
	self nodeStyler fontSize: 16.
	self nodeStyler popup text: [ :e | 
		e rawModel mooseName copyReplaceAll: '::' with: '.' ].
	spackageDict := Dictionary new.
	cpackageDict := Dictionary new.
	pNodes := OrderedCollection new
]

{ #category : #building }
MiNewVisuBuilder >> labelFromString: aString [

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
MiNewVisuBuilder >> mapModel [

	^ mapModel
]

{ #category : #accessing }
MiNewVisuBuilder >> mapModel: anObject [

	mapModel := anObject
]

{ #category : #accessing }
MiNewVisuBuilder >> mooseModel [

	self mapModel mooseModel
]

{ #category : #building }
MiNewVisuBuilder >> nodeAnnouncer [

	"plug new events here"

	baseNode ifNotNil: [ ^ baseNode announcer ].
	baseNode := RSComposite new
		            @ self nodeStyler popup;
		            @
			            (HGhostDraggable new color:
					             Smalltalk ui theme caretColor);
		            @ self menuInteraction;
		            @ self highlightable;
		            @ self highlightableLinkedShapes;
		            @ RSNodeOnTopWhenPositionChanged new;
		            @ HUpdateSelectionBox new;
		            @
			            (HResizeParentWhenChildMoves new nodeStyler:
					             self nodeStyler);
		            yourself.
	^ baseNode announcer
]

{ #category : #building }
MiNewVisuBuilder >> nodeIsShared: node [

	| c s |
	self flag: 'to modify'.
	c := false.
	s := false.
	node dependencies ifEmpty: [ ^ false ].
	node dependencies do: [ :d | 
		d to = node ifTrue: [ 
			| response |
			response := self classAlreadyPresent: d from rawModel.
			response = #client ifTrue: [ c := true ].
			response = #server ifTrue: [ s := true ] ] ].
	^ c & s
]

{ #category : #partitioning }
MiNewVisuBuilder >> packagePresentInBothSides: package [

	^ (spackageDict includesKey: package) and: [ 
		  cpackageDict includesKey: package ]
]

{ #category : #building }
MiNewVisuBuilder >> renderLinesIn: aCanvas [

	| announcer high |
	(RSLineBuilder line
		 attachPoint: RSShortestHorizontalAttachPoint new;
		 markerEnd: (RSShapeFactory arrow size: 10);
		 color: Smalltalk ui theme textColor translucent;
		 yourself)
		canvas: aCanvas;
		shapes: shapes;
		connectFromAll: #dependentsFromLinks.
	announcer := Announcer new.
	high := RSHighlightable red.
	high onShape: announcer.
	self menuInteraction onShape: announcer.
	aCanvas lines do: [ :line | 
		| f t |
		line announcer: announcer.
		f := line from model rawModel.
		t := line to model rawModel ]
]

{ #category : #visiting }
MiNewVisuBuilder >> roassalBorderFor: aSymbol [

	aSymbol = #dashed ifTrue: [ ^ self borderForSet ].
	aSymbol = #line ifTrue: [ ^ self shouldBeImplemented ].
	aSymbol = #without ifTrue: [ ^ nil ]
]

{ #category : #visiting }
MiNewVisuBuilder >> rsShapeFor: childrenNodes withRSLayout: aRoassalLayout [

	| group layoutChildrenNodes |
	layoutChildrenNodes := OrderedCollection new.
	group := RSGroup new.

	childrenNodes do: [ :c | group add: (c acceptVisitor: self) ].

	aRoassalLayout on: group.

	^ group asShape
]

{ #category : #building }
MiNewVisuBuilder >> services [

	mapModel clientLayers ifEmpty: [ 
		mapModel clientLayers add: (Dictionary sizeFor: self elements size) ].
	^ mapModel clientLayers at: 1
]

{ #category : #building }
MiNewVisuBuilder >> shapeFor: node [

	| shape |
	shape := RSComposite new
		         model: node;
		         color: Color transparent;
		         announcer: self nodeAnnouncer;
		         yourself.

	(node isExpanded and: [ node hasChildren ])
		ifTrue: [ self buildCompositeFullNodeIn: shape ]
		ifFalse: [ self buildCompositeEmptyNodeIn: shape ].
	node
		removeInteractionIfPresent: self class;
		when: HNodeAddedEvent do: [ :evt | self rebuildRootShape: shape ];
		when: HCollapseEvent do: [ :evt | self rebuildShape: shape ];
		when: HExpandEvent do: [ :evt | self rebuildRootShape: shape ];
		when: HNodeChangedEvent do: [ :evt | self rebuildShape: shape ].
	shapes add: shape.
	^ shape
]

{ #category : #building }
MiNewVisuBuilder >> updateBuild [

	self container shapes do: #remove.
	description := self buildDescription.
	self visit: description.
	rootNode hideAllLinks.
	self renderLinesIn: self container.
	self container signalUpdate
]

{ #category : #visiting }
MiNewVisuBuilder >> visit: aVisualizationModel [

	| rootShape |
	shapes := OrderedCollection new.
	rootNode := HNode new.
	rootShape := aVisualizationModel acceptVisitor: self.
	self container add: rootShape.
	self container schildren: shapes
]

{ #category : #visiting }
MiNewVisuBuilder >> visitBox: aMiNVBoxNode withRSLayout: aRoassalLayout [

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
MiNewVisuBuilder >> visitFlowBox: aMiNVBoxNode [

	^ self visitBox: aMiNVBoxNode withRSLayout: RSFlowLayout
]

{ #category : #visiting }
MiNewVisuBuilder >> visitHorizontalBox: aMiNVBoxNode [

	^ self visitBox: aMiNVBoxNode withRSLayout: RSHorizontalLineLayout
]

{ #category : #visiting }
MiNewVisuBuilder >> visitPackageElement: aPackageElement [

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
MiNewVisuBuilder >> visitQueryNode: aMiNVQueryNode [

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
MiNewVisuBuilder >> visitTypeElement: aMiLVTypeElement [

	| hNode shape |
	hNode := self createHNodeFor: aMiLVTypeElement.
	rootNode add: hNode.
	shape := (self shapeFor: hNode)
		         sparent: self container;
		         yourself.
	shapes add: shape.
	^ shape
]

{ #category : #visiting }
MiNewVisuBuilder >> visitVerticalBox: aMiNVBoxNode [

	^ self visitBox: aMiNVBoxNode withRSLayout: RSVerticalLineLayout
]
