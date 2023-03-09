Class {
	#name : #MiNewVisuBuilder,
	#superclass : #HSimpleVisualizationBuilder,
	#instVars : [
		'mapModel',
		'services',
		'implementations',
		'clients',
		'allEntities',
		'clients2',
		'serverDCR',
		'appServiceUID',
		'serverPackages',
		'clientPackages',
		'clientNodes',
		'serverNodes',
		'highlightShapes',
		'scale',
		'sharedNodes',
		'sharedDict',
		'dtoClasses',
		'currentGroups',
		'currentChildrenNodes',
		'allEnums',
		'allOtherClasses',
		'serverDCR2',
		'serverDCR3',
		'clients3',
		'clients4',
		'serverDCR4',
		'clients5',
		'serverDCR5',
		'clients6',
		'serverDCR6',
		'clients7',
		'serverDCR7',
		'clientDicts',
		'serverDicts',
		'spackageDict',
		'cpackageDict',
		'pNodes',
		'continueClient',
		'continueServer',
		'index',
		'order',
		'purgatoryDict'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #partitioning }
MiNewVisuBuilder >> addDependenciesFrom: sourcesDict to: targetsDict [

	self
		addDependenciesFrom: sourcesDict
		to: targetsDict
		execute: [ :a :b |  ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> addDependenciesFrom: sourcesDict to: targetsDict execute: aBlock [

	sourcesDict associationsDo: [ :a | 
		(self classDependenciesFor: a key) do: [ :d | 
			targetsDict at: d ifPresent: [ :target | 
				a value dependencyTo: target.
				aBlock value: a key value: d ] ] ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> addDependenciesToShared [

	"Add dependencies to shared from last added layers."

	[ sharedDict associationsDo: [ :a | 
		(self classDependantsFor: a key) do: [ :c | 
			(serverDicts at: index)
				at: c
				ifPresent: [ :n | n dependencyTo: a value ] ].
		(self classDependenciesFor: a key) do: [ :c | 
			(clientDicts at: index)
				at: c
				ifPresent: [ :n | a value dependencyTo: n ] ] ] ] timeToRun
		traceCr
]

{ #category : #partitioning }
MiNewVisuBuilder >> addLayer [

	continueClient ifTrue: [ 
		continueClient := self addLayerToClientFromLevel: index ].
	continueServer ifTrue: [ 
		continueServer := self addLayerToServerFromLevel: index ].
	index := index + 1.
	"self addDependenciesToShared"
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

	| hasAddedSomething newDict currentDict |
	hasAddedSomething := false.
	newDict := Dictionary new.
	currentDict := serverDicts at: level.
	currentDict associationsDo: [ :assoc | 
		| class hNode |
		class := assoc key.
		hNode := assoc value.
		(self classDependenciesFor: class) do: [ :d | 
			| response |
			response := self classAlreadyPresent: d.
			response = #free ifTrue: [ 
				| newNode |
				newNode := self buildNodeFromEntity: d.
				hNode dependencyTo: newNode.
				newDict at: d put: newNode.
				hasAddedSomething := true ].
			response = #client ifTrue: [ 
				(self indexOf: d in: clientDicts) > 1 ifTrue: [ 
					hNode dependencyTo: (self moveClass: d ToSharedfrom: clientDicts) ] ].
			response = #shared ifTrue: [ "hNode dependencyTo: (sharedDict at: d)"
				 ] ] ].
	hasAddedSomething ifTrue: [ 
		serverDicts add: newDict.
		^ true ].
	^ false
]

{ #category : #building }
MiNewVisuBuilder >> allEnums [

	^ allEnums ifNil: [ 
		  allEnums := OrderedCollection new "self services anyOne rawModel mooseModel allEnums 
			              collect: [ :c | 
			              self buildNodeFromEntity: c in: sharedDict ] " ]
]

{ #category : #building }
MiNewVisuBuilder >> allOtherModelClasses [

	^ allOtherClasses ifNil: [ 
		  allOtherClasses := OrderedCollection new "(self services anyOne rawModel mooseModel
			                      allModelClasses reject: [ :c | 
			                      c isAnonymousClass or: [ 
				                      (sharedDict
					                       at: c
					                       ifPresent: [ true ]
					                       ifAbsent: [ false ]) or: [ 
					                      (clientNodes
						                       at: c
						                       ifPresent: [ true ]
						                       ifAbsent: [ false ]) or: [ 
						                      serverNodes
							                      at: c
							                      ifPresent: [ true ]
							                      ifAbsent: [ false ] ] ] ] ]) collect: [ 
			                     :c | self buildNodeFromEntity: c ]" ]
]

{ #category : #building }
MiNewVisuBuilder >> appServiceUID [

	^ appServiceUID ifNil: [ 
		  appServiceUID := self buildNodeFromEntity: ((FQStringQuery
				                     property: #name
				                     comparator: #=
				                     valueToCompare: 'AppServiceUID') runOn:
				                    self services anyOne rawModel mooseModel
					                    allModelClasses) first ]
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

	| description next |
	self initializePartitioning.

	description := self buildDescription.

	self visit: description.

	next := RSBox new
		        size: 50;
		        color: (Color fromHexString: '67001F');
		        yourself.
	rootNode hideAllLinks.
	pNodes do: #showAllLinks.
	self container add: next.
	next setAsFixed.


	next when: RSMouseClick do: [ 
	"	next translateBy: -100 @ -100.
		self container exportToSVGCairo.
		next translateBy: 100 @ 100."
		self container shapes do: #remove.
		self addLayer.
		description := self buildDescription.
		self visit: description.
		rootNode hideAllLinks.
		pNodes do: #showAllLinks.
		"sharedDict associationsDo: [ :a | 
			a key class = FamixJavaEnum ifFalse: [ a value showAllLinks ] ]."
		self renderLinesIn: self container.
		self container signalUpdate ].

	self renderLinesIn: self container.
	self container @ self menuInteraction
]

{ #category : #building }
MiNewVisuBuilder >> buildClientPackageShape: package [

	| childrenShapes node titleGroup title titleBox children boxChildren titleRadius boxChildrenRadius list shape |
	shape := RSComposite new
		         model: package;
		         color: Color transparent;
		         yourself.
	shape border: (RSBorder new
			 width: 2;
			 capSquare;
			 joinMiter;
			 color: Smalltalk ui theme textColor;
			 dashArray: #( 5 );
			 yourself).
	node := package.
	titleGroup := self nodeStyler labelAndIconFor: node.
	titleBox := RSBox new
		            extent: titleGroup extent + 10;
		            color: (self container color);
		            position: titleGroup position;
		            yourself.
	title := RSComposite new
		         add: titleBox;
		         addAll: titleGroup;
		         adjustToChildren;
		         yourself.
	shape propertyAt: #background put: titleBox.
	childrenShapes := self childrenFor: node.
	RSHorizontalLineLayout new on: childrenShapes.

	shape schildren: childrenShapes.
	childrenShapes do: [ :child | child sparent: shape ].
	children := childrenShapes asShape padding: 10.
	childrenShapes do: [ :child | child model position: child position ].
	title width < children width
		ifTrue: [ 
			titleBox width: children width.
			title adjustToChildren ]
		ifFalse: [ children width: title width ].
	boxChildren := self boxChildrenFor: node.
	titleRadius := self topCornerRadius.
	boxChildrenRadius := self bottomCornerRadius.
	list := { 
		        title.
		        children }.
	self nodeStyler position = #below ifTrue: [ 
		titleRadius := self bottomCornerRadius.
		boxChildrenRadius := self topCornerRadius.
		list := { 
			        children.
			        title } ].
	RSVerticalLineLayout new
		gapSize: 0;
		on: list.
	titleBox cornerRadius: titleRadius.
	boxChildren
		cornerRadius: boxChildrenRadius;
		fromRectangle: children encompassingRectangle.

	shape
		add: title;
		add: children.
	shape adjustToChildren.
	^ shape
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

	| serverLayouts clientLayouts sharedGroups description |
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
MiNewVisuBuilder >> buildExtraNodeFromEntity: anEntity [

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
MiNewVisuBuilder >> buildLayoutsFor: dicts reversed: reverse [

	| layouts |
	layouts := dicts withIndexCollect: [ :d :i | 
		           | layout entities |
		           i = 1
			           ifTrue: [ 
				           layout := MiNVVerticalLayoutNode new.
				           entities := (self groupClassesByChar: d values) sort: [ 
					                       :a 
					                       :b | a name < b name ] ]
			           ifFalse: [ 
				           layout := MiNVFlowLayoutNode new.
				           entities := self commonPackagesFor: d values ].
		           layout
			           addAll: (entities collect: [ :c | 
						            MiNVElement new
							            model: c;
							            yourself ]);
			           yourself ].
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
MiNewVisuBuilder >> buildNodeFromEntity: anEntity in: aDict [

	| node |
	sharedDict at: anEntity ifPresent: [ ^ nil ].
	aDict at: anEntity ifPresent: [ :n | ^ n ].
	node := HNode new
		        name:
			        (String streamContents: [ :s | anEntity displayStringOn: s ]);
		        rawModel: anEntity;
		        iconName: #class;
		        collapse;
		        yourself.
	aDict at: anEntity put: node.
	^ node
]

{ #category : #building }
MiNewVisuBuilder >> buildShapes [

	| servicesShapes layout width implementationsShapes allShapes clientsShapes clientShape serverDCRShapes serverShape clientLabel serverLabel subClientShapes sharedShape sharedShapes ltt1 |
	clientLabel := self labelFromString: 'Client side'.
	serverLabel := self labelFromString: 'Server side'.

	layout := RSVerticalLineLayout new
		          alignLeft;
		          yourself.

	"---------------------
	BUILDING SHAPES
	---------------------"
	clientShape := RSComposite new.
	serverShape := RSComposite new.
	sharedShape := RSComposite new.

	sharedShapes := (self commonPackagesFor: self dtoClasses)
		                collect: [ :s | 
		                (self shapeFor: s) sparent: self container ]
		                as: RSGroup.
	servicesShapes := self services
		                  collect: [ :s | 
		                  (self shapeFor: s) sparent: self container ]
		                  as: RSGroup.
	clientsShapes := self clientPackages
		                 collect: [ :s | 
		                 (self shapeFor: s) sparent: self container ]
		                 as: RSGroup.
	clientsShapes sort: [ :a :b | a model name < b model name ].
	subClientShapes := clientsShapes flatCollect: [ :cs | 
		                   cs allChildren select: [ :s | 
			                   s isComposite and: [ s model notNil ] ] ].


	implementationsShapes := self implementations
		                         collect: [ :s | 
		                         (self shapeFor: s) sparent: self container ]
		                         as: RSGroup.

	serverDCRShapes := self serverPackages
		                   collect: [ :s | 
		                   (self shapeFor: s) sparent: self container ]
		                   as: RSGroup.
	serverDCRShapes sort: [ :a :b | a model name < b model name ].

	"---------------------
	ASPECT
	---------------------"
	width := (servicesShapes collect: #width) max.
	servicesShapes do: [ :s | 
		s children first width: width.
		s adjustToChildren ].

	width := (implementationsShapes collect: #width) max.
	implementationsShapes do: [ :s | 
		s children first width: width.
		s adjustToChildren ].

	clientLabel basicTranslateBy:
		(clientShape extent / -2 translateBy: clientLabel extent x @ 0).

	serverLabel basicTranslateBy:
		(serverShape extent / -2 translateBy: serverLabel extent x @ 0).

	clientShape border: self borderForSet.
	serverShape border: self borderForSet.
	sharedShape border: self borderForSet.
	"---------------------
	LAYOUT SHAPES
	---------------------"
	RSFlowLayout new on: serverDCRShapes.
	RSFlowLayout new on: sharedShapes.
	layout on: servicesShapes.
	RSFlowLayout new
		gapSize: 10;
		on: clientsShapes.
	layout on: implementationsShapes.



	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: { 
				clientsShapes.
				servicesShapes }.


	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: { 
				implementationsShapes.
				serverDCRShapes }.
	"---------------------
	ADDING SHAPES TO PARENTS
	---------------------"
	clientShape
		addAll: clientsShapes;
		addAll: servicesShapes;
		sparent: self container.

	serverShape
		addAll: implementationsShapes;
		addAll: serverDCRShapes;
		sparent: self container.

	sharedShape
		addAll: sharedShapes;
		sparent: self container.

	allShapes := RSGroup new.

	ltt1 := RSComposite new
		        add: clientShape;
		        add: serverShape;
		        yourself.

	allShapes
		add: sharedShape;
		add: ltt1.

	self container schildren:
		allShapes , clientsShapes , servicesShapes , implementationsShapes
		, serverDCRShapes, sharedShapes.

	sharedShape
		adjustToChildren;
		padding: 50.

	clientShape
		adjustToChildren;
		padding: 50.

	serverShape
		adjustToChildren;
		padding: 50.

	"clientShape add: clientLabel.
	serverShape add: serverLabel."

	self container addAll: allShapes.


	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: { 
				clientShape.
				serverShape }.
	ltt1 adjustToChildren.
	RSVerticalLineLayout new
		alignCenter;
		verticalGap: 400;
		on: { 
				sharedShape.
				ltt1 }
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

{ #category : #accessing }
MiNewVisuBuilder >> clientNodesFor: anHNode [

	| node cl |
	node := anHNode rawModel.
	cl := node incomingReferences collectAsSet: [ :r | self rootClass: r source ].

	^ cl collect: [ :c | self buildNodeFromEntity: c ]
]

{ #category : #building }
MiNewVisuBuilder >> clientPackages [

	^ clientPackages ifNil: [ 
		  clientPackages := self commonPackagesFor: self clients ]
]

{ #category : #building }
MiNewVisuBuilder >> clients [

	^ clients ifNil: [ 
		  clients := OrderedCollection new.
		  self services do: [ :s | 
			  s rawModel allClients do: [ :c | 
				  | client class |
				  class := self rootClass: c.
				  serverNodes
					  at: class
					  ifPresent: [ :n | 
						  n dependencyTo: s.
						  serverNodes removeKey: class.
						  serverDCR remove: n ifAbsent: [  ].
						  sharedDict at: class put: n.
						  sharedNodes add: n ]
					  ifAbsent: [ 
						  clientNodes
							  at: class
							  ifPresent: [ :hn | 
								  client := hn.
								  client dependencyTo: s ]
							  ifAbsent: [ 
								  client := self buildNodeFromEntity: class in: clientNodes.

								  client ifNotNil: [ 
									  client rawModel allProviders do: [ :p | 
										  serverNodes
											  at: p
											  ifPresent: [ :e | client dependencyTo: e ] ].
									  clients add: client ] ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> clients2 [

	^ clients2 ifNil: [ 
		  clients2 := OrderedCollection new.
		  self clients do: [ :s | 
			  s rawModel allClients do: [ :c | 
				  | client class |
				  class := self rootClass: c.
				  allEntities
					  at: class
					  ifPresent: [ :hn | 
						  client := hn.
						  client dependencyTo: s ]
					  ifAbsent: [ 
						  client := self buildNodeFromEntity: class in: allEntities.
						  client rawModel allProviders do: [ :p | 
							  allEntities at: p ifPresent: [ :e | client dependencyTo: e ] ].
						  client ifNotNil: [ clients2 add: client ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> clients3 [

	^ clients3 ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self clients2 do: [ :s | 
			  s rawModel incomingReferences do: [ :r | 
				  | client class |
				  class := self rootClass: r source.
				  allEntities
					  at: class
					  ifPresent: [ :hn | client := hn ]
					  ifAbsent: [ 
						  client := self buildNodeFromEntity: class in: allEntities.
						  client ifNotNil: [ nodes add: client ] ].
				  client dependencyTo: s ] ].
		  clients3 := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> clients4 [

	^ clients4 ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self clients3 do: [ :s | 
			  s rawModel incomingReferences do: [ :r | 
				  | client class |
				  class := self rootClass: r source.
				  allEntities
					  at: class
					  ifPresent: [ :hn | client := hn ]
					  ifAbsent: [ 
						  client := self buildNodeFromEntity: class in: allEntities.
						  client ifNotNil: [ nodes add: client ] ].
				  client dependencyTo: s ] ].
		  clients4 := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> clients5 [

	^ clients5 ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self clients4 do: [ :s | 
			  s rawModel incomingReferences do: [ :r | 
				  | client class |
				  class := self rootClass: r source.
				  allEntities
					  at: class
					  ifPresent: [ :hn | client := hn ]
					  ifAbsent: [ 
						  client := self buildNodeFromEntity: class in: allEntities.
						  client ifNotNil: [ nodes add: client ] ].
				  client dependencyTo: s ] ].
		  clients5 := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> clients6 [

	^ clients6 ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self clients5 do: [ :s | 
			  s rawModel incomingReferences do: [ :r | 
				  | client class |
				  class := self rootClass: r source.
				  allEntities
					  at: class
					  ifPresent: [ :hn | client := hn ]
					  ifAbsent: [ 
						  client := self buildNodeFromEntity: class in: allEntities.
						  client ifNotNil: [ nodes add: client ] ].
				  client dependencyTo: s ] ].
		  clients6 := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> clients7 [

	^ clients7 ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self clients6 do: [ :s | 
			  s rawModel incomingReferences do: [ :r | 
				  | client class |
				  class := self rootClass: r source.
				  allEntities
					  at: class
					  ifPresent: [ :hn | client := hn ]
					  ifAbsent: [ 
						  client := self buildNodeFromEntity: class in: allEntities.
						  client ifNotNil: [ nodes add: client ] ].
				  client dependencyTo: s ] ].
		  clients7 := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> colorFor: node [

	| entity |
	node color ifNotNil: [ :c | ^ c ].


	entity := node rawModel.
	entity isMooseObject ifFalse: [ ^ Color fromHexString: 'E0E0E0' ].

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
	^ Color fromHexString: 'E0E0E0'
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
		   (self buildExtraNodeFromEntity: a key)
			   addAll: a value;
			   iconName: #package;
			   yourself ]) sorted: [ :a :b | a name < b name ]
]

{ #category : #building }
MiNewVisuBuilder >> commonPackagesFor: classes in: aDict [

	| groups |
	groups := (classes groupedBy: [ :c | 
		           (c rawModel atScope: FamixTPackage) anyOne ])
		          associations.
	^ groups collect: [ :a | 
		  (self buildNodeFromEntity: a key in: aDict)
			  addAll: a value;
			  iconName: #package;
			  yourself ]
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

{ #category : #partitioning }
MiNewVisuBuilder >> dao [

	| sa |
	sa := (((FQStringQuery
		         property: #name
		         comparator: #=
		         valueToCompare: 'DaoAbstract') runOn:
		        self services anyOne rawModel mooseModel allClasses) 
		       reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.

	^ sa subclassHierarchy collect: [ :s | self buildNodeFromEntity: s ]
]

{ #category : #building }
MiNewVisuBuilder >> dtoClasses [

	^ dtoClasses ifNil: [ 
		  dtoClasses := OrderedCollection new
		  "dtoClasses addAll: ((((FQStringQuery
				      property: #name
				      comparator: #beginsWith:
				      valueToCompare: 'BaseModel') runOn:
				     self services anyOne rawModel mooseModel allClasses) 
				    flatCollect: [ :b | b subclassHierarchy ])
				   collect: [ :c | self buildNodeFromEntity: c in: sharedDict ]
				   thenReject: #isNil)" ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> eServices [

	| sa |
	sa := (((FQStringQuery
		         property: #name
		         comparator: #=
		         valueToCompare: 'ServiceAbstract') runOn:
		        self services anyOne rawModel mooseModel allClasses) 
		       reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.

	^ sa subclassHierarchy collect: [ :s | self buildNodeFromEntity: s ]
]

{ #category : #building }
MiNewVisuBuilder >> elements [

	| entities |
	entities := OrderedCollection new.
	entities addAll:
		(mapModel entities sort: [ :a :b | a name < b name ]).

	^ entities collect: [ :e | 
		  self buildNodeFromEntity: e in: clientNodes ]
]

{ #category : #building }
MiNewVisuBuilder >> entityIsInClientPackage: anEntity [

	| b |
	b := false.
	(anEntity isPackage and: [ anEntity name = 'client' ]) ifTrue: [ 
		^ true ].

	anEntity
		allAtScope: FamixTPackage
		until: [ :p | b := p name = 'client' ].

	^ b
]

{ #category : #building }
MiNewVisuBuilder >> entryPoints [

	| ep eps |
	ep := ((FQStringQuery
		        property: #name
		        comparator: #=
		        valueToCompare: 'EntryPoint') runOn:
		       self services anyOne rawModel mooseModel) anyOne.
	eps := ep subclassHierarchyGroup.
	self classAlreadyPresent: eps first
]

{ #category : #partitioning }
MiNewVisuBuilder >> fetchNodeFor: aClass in: dicts [

	dicts do: [ :d | d at: aClass ifPresent: [ :n | ^ n ] ].
	^ nil
]

{ #category : #building }
MiNewVisuBuilder >> groupClassesByChar: classes [

	| groups |
	classes ifEmpty: [ ^ OrderedCollection new ].
	groups := (classes groupedBy: [ :c | 
		           (c name at:
			            (((c name beginsWith: 'Uc') or: [ 
				              c name beginsWith: 'UC' ])
				             ifTrue: [ 3 ]
				             ifFalse: [ 1 ])) uppercase ]) associations.
	^ (groups collect: [ :a | 
		   (self buildExtraNodeFromEntity: a key)
			   addAll: a value;
			   yourself ]) sorted: [ :a :b | a name < b name ]
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

{ #category : #building }
MiNewVisuBuilder >> implementations [

	^ implementations ifNil: [ 
		  implementations := self services collect: [ :s | 
			                     | newEntity |
			                     newEntity := self
				                                  buildNodeFromEntity:
					                                  (s rawModel subclassHierarchy 
						                                   detect: [ :sub | 
						                                   sub isInterface not and: [ 
							                                   sub isAbstract isNil ] ])
				                                  in: serverNodes.
			                     s dependencyTo: newEntity.
			                     newEntity ] ]
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
	allEntities := Dictionary new.
	clientNodes := Dictionary new.
	pNodes := OrderedCollection new.
	serverNodes := Dictionary new.
	sharedNodes := OrderedCollection new.
	sharedDict := Dictionary new.
	purgatoryDict := Dictionary new.
	clientDicts := OrderedCollection new.
	serverDicts := OrderedCollection new.
	scale := NSScale pow
		         domain: #( 1 500 );
		         range: { 
				         Color white.
				         (Color fromHexString: '40004B') }
]

{ #category : #partitioning }
MiNewVisuBuilder >> initializeFirstClientLayer [

	clientDicts add: Dictionary new. "Initialisation of the fist layer of clients"
	mapModel entities do: [ :e | 
		(clientDicts at: 1) at: e put: (self buildNodeFromEntity: e) ]
]

{ #category : #partitioning }
MiNewVisuBuilder >> initializeFirstServerLayer [

	serverDicts add: Dictionary new.
	(clientDicts at: 1) associationsDo: [ :assoc | 
		| impl class hNode newNode |
		class := assoc key.
		hNode := assoc value.
		impl := class subclassHierarchy detect: [ :sub | 
			        sub isInterface not and: [ sub isAbstract isNil ] ].
		newNode := self buildNodeFromEntity: impl.
		newNode dependencyTo: hNode.
		(serverDicts at: 1) at: impl put: newNode ]
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

	| baseModel |
	baseModel := (((FQStringQuery
		                property: #name
		                comparator: #=
		                valueToCompare: 'BaseModelData') runOn:
		               self services anyOne rawModel mooseModel allClasses) 
		              reject: [ :c | c subclassHierarchy isEmpty ]) anyOne.

	baseModel subclassHierarchy do: [ :c | 
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
		  color: self container color;
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

	^ self mapModel mooseModel
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

{ #category : #accessing }
MiNewVisuBuilder >> renderIn: aCanvas [

	aCanvas color: Smalltalk ui theme backgroundColor.
	shapes := RSGroup new.
	self buildShapes.
	aCanvas @ self menuInteraction.

	self renderLinesIn: aCanvas
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
		t := line to model rawModel.
		line color: Color red.
		"((f mooseName includesSubstring: '::client') and: [ 
			 (t mooseName includesSubstring: '::client') not ]) ifTrue: [ 
			line
				width: 3;
				color: Color magenta ].
"
		"	
	(((self serverPackages collect: #rawModel) includes: f) and: [ (f mooseName includesSubstring: '::client' )
	and: [( (self clientPackages collect: #rawModel) includes: t) and: [ (t mooseName includesSubstring: '::client') not ] ] ]) ifTrue: [ 	line
				width: 3;
				color: Color green muchDarker  ].
	"
		"(t isClass and: [ 
			 f isClass and: [ 
				 (f queryAllOutgoing intersection: t queryAllIncoming) 
					 allSatisfy: [ :a | a class = FamixJavaAccess ] ] ]) ifTrue: [ 
			line
				width: 3;
				color: Color red ]"

		"(f isMooseEntity & t isMooseEntity and: [ 
			 f isClass & t isClass and: [ 
				 (f superclassHierarchy anySatisfy: [ :c | 
					  c name = 'RemoteService' ]) and: [ 
					 t superclassHierarchy anySatisfy: [ :c | 
						 c name = 'CAInovelanRemoteServiceServlet' ] ] ] ]) ifTrue: [ 
			line
				dashed;
				color: Color green ]" ]
]

{ #category : #building }
MiNewVisuBuilder >> rootClass: anEntity [

	^ (anEntity atScopeWithProperty: [ :c | 
		   c isType and: [ 
			   c isException or: [ 
				   c isInterface or: [ 
					   c isParameterizedType or: [ 
						   c class = FamixJavaEnum or: [ 
							   c isClass and: [ c isAnonymousClass not ] ] ] ] ] ] ])
		  anyOne
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR [

	^ serverDCR ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  self implementations do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | c isStub ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli do: [ :e | 
				  clientNodes
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  serverNodes
							  at: e
							  ifPresent: [ :n | i dependencyTo: n ]
							  ifAbsent: [ 
								  | newNode |
								  newNode := self buildNodeFromEntity: e in: serverNodes.
								  newNode ifNotNil: [ 
									  i dependencyTo: newNode.
									  sdcr add: newNode ] ] ] ] ].
		  serverDCR := sdcr asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR2 [

	^ serverDCR2 ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  serverDCR2 := OrderedCollection new.
		  self serverDCR do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli asSet do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: allEntities.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  serverDCR2 add: newNode ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR3 [

	^ serverDCR3 ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  serverDCR3 := OrderedCollection new.
		  self serverDCR2 do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli asSet do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: allEntities.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  serverDCR3 add: newNode ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR4 [

	^ serverDCR4 ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  serverDCR4 := OrderedCollection new.
		  self serverDCR3 do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli asSet do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: allEntities.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  serverDCR4 add: newNode ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR5 [

	^ serverDCR5 ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  serverDCR5 := OrderedCollection new.
		  self serverDCR4 do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli asSet do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: allEntities.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  serverDCR5 add: newNode ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR6 [

	^ serverDCR6 ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  serverDCR6 := OrderedCollection new.
		  self serverDCR5 do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli asSet do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: allEntities.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  serverDCR6 add: newNode ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR7 [

	^ serverDCR7 ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  serverDCR7 := OrderedCollection new.
		  self serverDCR6 do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli asSet do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: allEntities.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  serverDCR7 add: newNode ] ] ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> serverPackages [

	^ serverPackages ifNil: [ 
		  serverPackages := self commonPackagesFor: self serverDCR ]
]

{ #category : #building }
MiNewVisuBuilder >> services [

	clientDicts ifEmpty: [ 
		clientDicts add: (Dictionary sizeFor: self elements size) ].
	^ clientDicts at: 1
]

{ #category : #building }
MiNewVisuBuilder >> setClientServerDependencies [

	self serverDCR, self implementations do: [ :s | 
		(s rawModel allProviders collect: [ :p | self rootClass: p ]) do: [ 
			:r | 
			clientNodes at: r ifPresent: [ :n | s dependencyTo: n ].
			sharedDict at: r ifPresent: [ :n | s dependencyTo: n ] ].

		(s rawModel allClients collect: [ :p | self rootClass: p ]) do: [ :r | 
			clientNodes at: r ifPresent: [ :n | n dependencyTo: s ].
			sharedDict at: r ifPresent: [ :n | n dependencyTo: s ] ] ].
	self clients do: [ :s | 
		(s rawModel allProviders collect: [ :p | self rootClass: p ]) do: [ 
			:r | sharedDict at: r ifPresent: [ :n | s dependencyTo: n ] ].
		(s rawModel allClients collect: [ :p | self rootClass: p ]) do: [ :r | 
			sharedDict at: r ifPresent: [ :n | n dependencyTo: s ] ] ]
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

{ #category : #visiting }
MiNewVisuBuilder >> visit: aVisualizationModel [

	| rootShape |
	shapes := OrderedCollection new.
	rootNode := HNode new.
	currentChildrenNodes := OrderedCollection new.
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
		padding: 50.
	shape add: label.
	label pushBack. 
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
		  withRSLayout: RSFlowLayout new
]

{ #category : #visiting }
MiNewVisuBuilder >> visitHorizontalLayout: aMiNVHorizontalLayoutNode [

	^ self
		  visitLayout: aMiNVHorizontalLayoutNode
		  withRSLayout: (RSHorizontalLineLayout new
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
		group add: (c acceptVisitor: self) ].

	aRoassalLayout on: group.

	^ group asShape
]

{ #category : #visiting }
MiNewVisuBuilder >> visitQueryNode: aMiNVQueryNode [

	| nodes |
	nodes := aMiNVQueryNode query value collect: [ :i | 
		         HNode new
			         rawModel: i;
			         name: i asString;
			         yourself ].
	currentChildrenNodes addAll: nodes.
	^ nodes collect: [ :node | self shapeFor: node ] as: RSGroup
]

{ #category : #visiting }
MiNewVisuBuilder >> visitVerticalLayout: aMiNVVerticalLayoutNode [

	^ self
		  visitLayout: aMiNVVerticalLayoutNode
		  withRSLayout: (RSVerticalLineLayout new
				   alignCenter;
				   gapSize: aMiNVVerticalLayoutNode gapSize;
				   yourself)
]
