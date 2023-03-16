Class {
	#name : #MiNewVisuBuilder,
	#superclass : #HSimpleVisualizationBuilder,
	#instVars : [
		'mapModel',
		'highlightShapes',
		'sharedDict',
		'clientDicts',
		'serverDicts',
		'spackageDict',
		'cpackageDict',
		'pNodes',
		'continueClient',
		'continueServer',
		'index',
		'order',
		'description',
		'purgatoryDict'
	],
	#category : #'MooseIDE-NewVisu-Roassal-builder'
}

{ #category : #partitioning }
MiNewVisuBuilder >> addDependenciesToShared [

	"Add dependencies to shared from last added layers."

	sharedDict associationsDo: [ :a | 
		(self classDependantsFor: a key) do: [ :c | 
			(serverDicts at: index)
				at: c
				ifPresent: [ :n | n dependencyTo: a value ] ].
		(self classDependenciesFor: a key) do: [ :c | 
			(clientDicts at: index)
				at: c
				ifPresent: [ :n | a value dependencyTo: n ] ] ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> addLayer [

	continueClient ifTrue: [ 
		continueClient := self addLayerToClientFromLevel: index ].
	continueServer ifTrue: [ 
		continueServer := self addLayerToServerFromLevel: index ].
	index := index + 1.
	self addDependenciesToShared
]

{ #category : #partitioning }
MiNewVisuBuilder >> addLayerToClientFromLevel: level [

	| newDict currentDict hasAddedSomething |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := clientDicts at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #server ifTrue: [ 
				(self indexOf: d in: serverDicts) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d ToSharedfrom: serverDicts) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ].
		(self classDependantsFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #free ifTrue: [ 
				| newNode |
				newNode := self buildNodeFromEntity: d.
				newNode dependencyTo: hNode.
				newDict at: d put: newNode.
				hasAddedSomething := true ].
			response = #client ifTrue: [ 
				newDict at: d ifPresent: [ :n | n dependencyTo: hNode ] ].
			response = #server ifTrue: [ 
				(self indexOf: d in: serverDicts) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d ToSharedfrom: serverDicts) ] ].
			response = #shared ifTrue: [ "(sharedDict at: d) dependencyTo: hNode"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		clientDicts add: newDict.
		^ true ].
	^ false
]

{ #category : #partitioning }
MiNewVisuBuilder >> addLayerToServerFromLevel: level [

	| newDict currentDict |
	newDict := Dictionary new.
	currentDict := serverDicts at: level.

	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependantsFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #client ifTrue: [  ] ].

		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #free ifTrue: [ 
				| newNode |
				newNode := self buildNodeFromEntity: d.
				hNode dependencyTo: newNode.
				newDict at: d put: newNode ].
			response = #client ifTrue: [ 
				(self indexOf: d in: clientDicts) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d ToSharedfrom: clientDicts) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	newDict ifNotEmpty: [ 
		serverDicts add: newDict.
		^ true ].
	^ false
]

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
		self addLayer.

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

	self initializePartitioning.
	
	description := self buildDescription.

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
	serverLayouts := self buildLayoutsFor: serverDicts reversed: false.
	clientLayouts := self buildLayoutsFor: clientDicts reversed: true.
	
	sharedGroups := sharedDict values groupedBy: [ :n | 
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

	(description := MiNVVerticalLayoutNode new)
		gapSize: 90;
		add: (MiNVBoxNode new
				 name: 'Shared';
				 layout: (MiNVFlowLayoutNode new
						  gapSize: 80;
						  add: (MiNVBoxNode new
								   name:
									   'DTOs: ' , (sharedGroups at: #dto) size asString
									   , ' classes';
								   layout: (MiNVFlowLayoutNode new
										    gapSize: 80;
										    addAll:
											    ((self commonPackagesFor: (sharedGroups at: #dto)) 
												     collect: [ :c | 
													     MiNVElement new
														     model: c;
														     yourself ]);
										    yourself);
								   yourself);
						  add: (MiNVBoxNode new
								   name:
									   'Enums: ' , (sharedGroups at: #enum) size asString
									   , ' classes';
								   layout: (MiNVFlowLayoutNode new
										    gapSize: 80;
										    addAll:
											    ((self commonPackagesFor: (sharedGroups at: #enum)) 
												     collect: [ :c | 
													     MiNVElement new
														     model: c;
														     yourself ]);
										    yourself);
								   yourself);
						  yourself);
				 yourself);
		add: (MiNVHorizontalLayoutNode new
				 gapSize: 90;
				 add: (MiNVBoxNode new
						  name: 'Client';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: clientLayouts;
								   yourself);
						  yourself);
				 add: (MiNVBoxNode new
						  name: 'Server';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   addAll: serverLayouts;
								   yourself);
						  yourself);
				 yourself);
		add: (MiNVBoxNode new
				 name: 'Purgatory: ', (purgatoryDict values) size asString, ' classes';
				 layout: (MiNVFlowLayoutNode new
						  addAll:
							  ((self commonPackagesFor: (purgatoryDict values))
								   collect: [ :c | 
									   MiNVElement new
										   model: c;
										   yourself ]);
						  yourself);
				 yourself).
	^ description
]

{ #category : #building }
MiNewVisuBuilder >> buildFirstDescription [

	| sharedGroups |
	sharedGroups := Dictionary new.
	sharedGroups at: #dto put: sharedDict values.
	sharedGroups at: #enum put: #(  ).
	(description := MiNVVerticalLayoutNode new)
		gapSize: 90;
		add: (MiNVBoxNode new
				 name: 'Shared';
				 layout: (MiNVFlowLayoutNode new
						  gapSize: 80;
						  add: (MiNVBoxNode new
								   name:
									   'DTOs: ' , (sharedGroups at: #dto) size asString
									   , ' classes';
								   layout: (MiNVFlowLayoutNode new
										    gapSize: 80;
										    add: (MiNVQueryNode new
												     layout: MiNVFlowLayoutNode;
												     query: [ mapModel dtos ];
												     yourself);
										    yourself);
								   yourself);
						  add: (MiNVBoxNode new
								   name:
									   'Enums: ' , (sharedGroups at: #enum) size asString
									   , ' classes';
								   layout: (MiNVFlowLayoutNode new
										    gapSize: 80;
										    addAll:
											    ((self commonPackagesFor: (sharedGroups at: #enum)) 
												     collect: [ :c | 
													     MiNVElement new
														     model: c;
														     yourself ]);
										    yourself);
								   yourself);
						  yourself);
				 yourself);
		add: (MiNVHorizontalLayoutNode new
				 gapSize: 90;
				 add: (MiNVBoxNode new
						  name: 'Client';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   add: (MiNVQueryNode new
										    layout: MiNVVerticalLayoutNode;
										    query: [ mapModel interfaces ];
										    yourself);
								   yourself);
						  yourself);
				 add: (MiNVBoxNode new
						  name: 'Server';
						  layout: (MiNVHorizontalLayoutNode new
								   gapSize: 80;
								   add: (MiNVQueryNode new
										    layout: MiNVVerticalLayoutNode;
										    query: [ mapModel implementations ];
										    yourself);
								   yourself);
						  yourself);
				 yourself);
		add: (MiNVBoxNode new
				 name:
					 'Purgatory: ' , purgatoryDict values size asString , ' classes';
				 layout: (MiNVFlowLayoutNode new
						  addAll:
							  ((self commonPackagesFor: purgatoryDict values) collect: [ :c | 
									   MiNVElement new
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

				           layout := MiNVVerticalLayoutNode new.
				           box := MiNVBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself.
				           entities := filtered sort: [ :a :b | a name < b name ] ]
			           ifFalse: [ 
				           filtered := (self entitiesWithViolationFrom: d)
					                       asOrderedCollection.
				           layout := MiNVFlowLayoutNode new.
				           entities := self commonPackagesFor: filtered.
				           box := MiNVBoxNode new
					                  name:
						                  filtered size asString , '/'
						                  , d values size asString;
					                  layout: layout;
					                  yourself ].
		           layout addAll: (entities collect: [ :c | 
				            MiNVElement new
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

{ #category : #partitioning }
MiNewVisuBuilder >> classAlreadyPresent: aClass [

	clientDicts do: [ :d | d at: aClass ifPresent: [ ^ #client ] ].
	serverDicts do: [ :d | d at: aClass ifPresent: [ ^ #server ] ].
	sharedDict at: aClass ifPresent: [ ^ #shared ].
	purgatoryDict at: aClass ifPresent: [ ^ #purgatory ].
	^ #free
]

{ #category : #partitioning }
MiNewVisuBuilder >> classDependantsFor: aClass [

	^ ((aClass queryAllIncoming withoutSelfLoops reject: [ :a | 
		    (a target isCollection
			     ifTrue: [ a target first ]
			     ifFalse: [ a target ]) isStub ]) collect: [ :e | 
		   self rootClass: e source ]) asSet
]

{ #category : #partitioning }
MiNewVisuBuilder >> classDependenciesFor: aClass [

	^ (aClass allProviders
		  reject: [ :c | c isStub ]
		  thenCollect: [ :e | self rootClass: e ]) asSet
]

{ #category : #building }
MiNewVisuBuilder >> colorFor: node [

	| entity |
	node color ifNotNil: [ :c | ^ c ].
	entity := node rawModel.

	(entity isType and: [ 
		 (sharedDict includesKey: entity) and: [ self nodeIsShared: node ] ]) 
		ifTrue: [ ^ Color fromHexString: '9970AB' ].

	(entity isPackage and: [ 
		 (sharedDict includesKey: node children anyOne rawModel) and: [ 
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

{ #category : #partitioning }
MiNewVisuBuilder >> computePartitioning [

	
	self initializeFirstClientLayer.
	self initializeFirstServerLayer.
	self initializeSharedWithDTOs.

	continueClient := true.
	continueServer := true.
	index := 1.


	continueServer ifTrue: [ 
		continueServer := self addLayerToServerFromLevel: index ].
	continueClient ifTrue: [ 
		continueClient := self addLayerToClientFromLevel: index ].
	index := index + 1
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

{ #category : #partitioning }
MiNewVisuBuilder >> fetchNodeFor: aClass in: dicts [

	dicts do: [ :d | d at: aClass ifPresent: [ :n | ^ n ] ].
	^ nil
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

{ #category : #partitioning }
MiNewVisuBuilder >> indexOf: aClass in: dicts [

	dicts withIndexDo: [ :d :i | d at: aClass ifPresent: [ ^ i ] ].
	^ -1
]

{ #category : #initialization }
MiNewVisuBuilder >> initialize [

	super initialize.
	self nodeStyler fontSize: 16.
	self nodeStyler popup text: [ :e | 
		e rawModel mooseName copyReplaceAll: '::' with: '.' ].
	spackageDict := Dictionary new.
	cpackageDict := Dictionary new.
	pNodes := OrderedCollection new.
	sharedDict := Dictionary new.
	clientDicts := OrderedCollection new.
	serverDicts := OrderedCollection new.
	purgatoryDict := Dictionary new
]

{ #category : #partitioning }
MiNewVisuBuilder >> initializeFirstClientLayer [

	"Initialisation of the fist layer of clients"
	clientDicts add: Dictionary new.
	mapModel interfaces do: [ :e | 
		(clientDicts at: 1) at: e put: (self buildNodeFromEntity: e) ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> initializeFirstServerLayer [

	serverDicts add: Dictionary new.
	mapModel implementations do: [ :e | 
		(serverDicts at: 1) at: e put: (self buildNodeFromEntity: e) ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> initializePartitioning [

	
	self initializeFirstClientLayer.
	self initializeFirstServerLayer.
	self initializeSharedWithDTOs.

	continueClient := true.
	continueServer := true.
	index := 1.
	order := 1
]

{ #category : #partitioning }
MiNewVisuBuilder >> initializeSharedWithDTOs [

	mapModel dtos do: [ :c |
		sharedDict at: c put: (self buildNodeFromEntity: c) ]
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

{ #category : #partitioning }
MiNewVisuBuilder >> moveClass: aClass ToSharedfrom: collectionOfDicts [

	| hNode |
	collectionOfDicts do: [ :d | 
		(d removeKey: aClass ifAbsent: [ nil ]) ifNotNil: [ :n | 
			hNode := n.
			purgatoryDict at: aClass put: hNode.
			^ hNode ] ].

	^ nil
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
MiNewVisuBuilder >> roassalLayout: aMiNVLayout [

	aMiNVLayout = MiNVHorizontalLayoutNode ifTrue: [ ^ RSHorizontalLineLayout ].
	aMiNVLayout = MiNVVerticalLayoutNode ifTrue: [ ^ RSVerticalLineLayout ].
	aMiNVLayout = MiNVFlowLayoutNode ifTrue: [ ^ RSFlowLayout ].
	^ RSFlowLayout
]

{ #category : #building }
MiNewVisuBuilder >> rootClass: anEntity [

	^ (anEntity atScopeWithProperty: [ :c | 
		   c isType and: [ c isAnonymousClass not ] ]) anyOne
]

{ #category : #building }
MiNewVisuBuilder >> services [

	clientDicts ifEmpty: [ 
		clientDicts add: (Dictionary sizeFor: self elements size) ].
	^ clientDicts at: 1
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
MiNewVisuBuilder >> visitBox: aMiNVBoxNode [

	| shape label |
	label := self labelFromString: aMiNVBoxNode name.

	shape := RSComposite new.
	shape add: (aMiNVBoxNode layout acceptVisitor: self).
	shape
		adjustToChildren;
		border: self borderForSet;
		padding: 50;
		color: (Color fromHexString: '00000010').
	shape add: label.
	shape
		when: RSMouseLeave do: [ :evt | 
			evt shape
				color: (Color fromHexString: '00000010');
				signalUpdate ];
		when: RSMouseEnter do: [ :evt | 
		evt shape
			color: (Color fromHexString: '80CDC150');
			signalUpdate ].
	RSLocation new
		left;
		top;
		inner;
		move: label on: shape baseRectangle.
	^ shape
]

{ #category : #visiting }
MiNewVisuBuilder >> visitElement: aMiNVElement [

	| hNode shape |
	hNode := aMiNVElement model.
	rootNode add: hNode.
	shape := (self shapeFor: hNode)
		         sparent: self container;
		         yourself.
	shapes add: shape.
	^ shape
]

{ #category : #visiting }
MiNewVisuBuilder >> visitFlowLayout: aMiNVFlowLayoutNode [

	^ self
		  visitLayout: aMiNVFlowLayoutNode
		  withRSLayout: (self roassalLayout: aMiNVFlowLayoutNode class) new
]

{ #category : #visiting }
MiNewVisuBuilder >> visitHorizontalLayout: aMiNVHorizontalLayoutNode [

	^ self
		  visitLayout: aMiNVHorizontalLayoutNode
		  withRSLayout:
			  ((self roassalLayout: aMiNVHorizontalLayoutNode class) new
				   gapSize: aMiNVHorizontalLayoutNode gapSize;
				   alignMiddle;
				   yourself)
]

{ #category : #visiting }
MiNewVisuBuilder >> visitLayout: aMiNVLayoutNode withRSLayout: aRoassalLayout [

	| group layoutChildrenNodes |
	layoutChildrenNodes := OrderedCollection new.
	group := RSGroup new.

	aMiNVLayoutNode children do: [ :c | 
		 group add: (c acceptVisitor: self)].

	aRoassalLayout on: group.

	^ group asShape
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
MiNewVisuBuilder >> visitVerticalLayout: aMiNVVerticalLayoutNode [

	^ self
		  visitLayout: aMiNVVerticalLayoutNode
		  withRSLayout: ((self roassalLayout: aMiNVVerticalLayoutNode class) new
				   alignCenter;
				   gapSize: aMiNVVerticalLayoutNode gapSize;
				   yourself)
]
