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
		'currentChildrenNodes'
	],
	#category : #'MooseIDE-NewVisu'
}

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
		  width: 2;
		  capSquare;
		  joinMiter;
		  color: Smalltalk ui theme textColor;
		  dashArray: #( 5 10 );
		  yourself
]

{ #category : #building }
MiNewVisuBuilder >> boxChildrenColorFor: anHNode [

	^ Color fromHexString: 'CCCCCC'
]

{ #category : #building }
MiNewVisuBuilder >> build [

	
	rootNode := HNode new.
	rootNode addAll: self dtoClasses.
	rootNode addAll: self implementations.
	rootNode addAll: self serverPackages.
	rootNode addAll: self services.
	rootNode addAll: self clientPackages.
	
	"Build tree representing the desired layout. "
	
	self setClientServerDependencies.
	self renderIn: self container.
	^ self container
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
MiNewVisuBuilder >> buildNodeFromEntity: anEntity [

	| node |
	allEntities at: anEntity ifPresent: [ :n | ^ n ].
	node := HNode new
		        name:
			        (String streamContents: [ :s | anEntity displayStringOn: s ]);
		        rawModel: anEntity;
		        iconName: #class;
		        collapse;
		        yourself.
	allEntities at: anEntity put: node.
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
		  clientPackages := self commonPackagesFor: self clients in: clientNodes]
]

{ #category : #building }
MiNewVisuBuilder >> clients [

	^ clients ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self services do: [ :s | 
			  s rawModel incomingReferences do: [ :r | 
				  | client |
				  client := self
					            buildNodeFromEntity:
						            (r source atScopeWithProperty: [ :e | 
							             e isClass and: [ e isAnonymousClass not ] ])
							            anyOne
					            in: clientNodes.
				  client ifNotNil: [ 
					  client dependencyTo: s.
					  nodes add: client ] ] ].
		  clients := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> colorFor: node [

	(node rawModel isClass and: [ 
		 node parent rawModel notNil and: [ 
			 node parent rawModel isPackage and: [ 
				 clientNodes
					 at: node rawModel
					 ifPresent: [ true ]
					 ifAbsent: [ false ] ] ] ]) ifTrue: [ 
		^ scale scale:
			  (node rawModel incomingReferences collectAsSet: [ :c | 
				   self rootClass: c source ]) size + 1 ].
	mapModel shouldColor ifFalse: [ ^ Color fromHexString: '7FC6F6' ].

	^ (node rawModel mooseName includesSubstring: '::client')
		  ifTrue: [ Color fromHexString: '7FC6F6' ]
		  ifFalse: [ Color fromHexString: 'FFABA3' ]
]

{ #category : #building }
MiNewVisuBuilder >> commonPackagesFor: classes [

	| groups |
	groups := (classes groupedBy: [ :c | 
		           (c rawModel atScope: FamixTPackage) anyOne ])
		          associations.
	^ groups collect: [ :a | 
		  (self buildNodeFromEntity: a key)
			  addAll: a value;
			  iconName: #package;
			  yourself ]
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

{ #category : #building }
MiNewVisuBuilder >> dtoClasses [

	^ dtoClasses ifNil: [ 
		  dtoClasses := OrderedCollection new.
		  dtoClasses addAll: ((((FQStringQuery
				      property: #beginsWith:
				      comparator: #=
				      valueToCompare: 'BaseModel') runOn:
				     self services anyOne rawModel mooseModel allClasses) 
				    flatCollect: [ :b | b subclassHierarchy ]) collect: [ :c | 
				   self buildNodeFromEntity: c in: sharedDict ]).
		  dtoClasses addAll:
			  (self services anyOne rawModel mooseModel allEnums collect: [ :c | 
				   self buildNodeFromEntity: c in: sharedDict ]) ]
]

{ #category : #building }
MiNewVisuBuilder >> elements [

	| entities |
	entities := OrderedCollection new.
	entities addAll:
		(mapModel entities sort: [ :a :b | a name < b name ]).

	^ entities collect: [ :e | self buildNodeFromEntity: e in: clientNodes ]
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
			                     newEntity := self buildNodeFromEntity:
				                                  (s rawModel subclassHierarchy 
					                                   detect: [ :sub | 
					                                   sub isInterface not and: [ 
						                                   sub isAbstract isNil ] ]) in: serverNodes.
			                     s dependencyTo: newEntity.
			                     newEntity ] ]
]

{ #category : #initialization }
MiNewVisuBuilder >> initialize [

	super initialize.
	self nodeStyler fontSize: 16.
	self nodeStyler popup text: [ :e | 
		e rawModel mooseName copyReplaceAll: '::' with: '.' ].
	allEntities := Dictionary new.
	clientNodes := Dictionary new.
	serverNodes := Dictionary new.
	sharedNodes := OrderedCollection new.
	sharedDict := Dictionary new.
	scale := NSScale pow
		         domain: #( 1 500 );
		         range: { 
				         Color white.
				         (Color fromHexString: '40004B') }
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
	
	
		(f isMooseEntity & t isMooseEntity and: [ 
			 f isClass & t isClass and: [ 
				 (f superclassHierarchy anySatisfy: [ :c | 
					  c name = 'RemoteService' ]) and: [ 
					 t superclassHierarchy anySatisfy: [ :c | 
						 c name = 'CAInovelanRemoteServiceServlet' ] ] ] ]) ifTrue: [ 
			line
				dashed;
				color: Color green ] ]
]

{ #category : #building }
MiNewVisuBuilder >> rootClass: anEntity [

	^ (anEntity atScopeWithProperty: [ :c | 
		   c isType and: [ c isAnonymousClass not ] ]) anyOne
]

{ #category : #building }
MiNewVisuBuilder >> serverDCR [

	^ serverDCR ifNil: [ 
		  | sdcr |
		  sdcr := Set new.
		  self implementations do: [ :i | 
			  | cli |
			  cli := i rawModel allProviders
				         reject: [ :c | 
					         c isStub or: [ 
						         c isClass and: [ 
							         c superclassHierarchy anySatisfy: [ :sc | 
								         sc name = 'RemoteServiceServlet' or: [ 
									         sc name = 'RemoteService' ] ] ] ] ]
				         thenCollect: [ :e | self rootClass: e ].
			  cli do: [ :e | 
				  serverNodes
					  at: e
					  ifPresent: [ :n | i dependencyTo: n ]
					  ifAbsent: [ 
						  | newNode |
						  newNode := self buildNodeFromEntity: e in: serverNodes.
						  newNode ifNotNil: [ 
							  i dependencyTo: newNode.
							  sdcr add: newNode ] ] ] ].
		  serverDCR := sdcr asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> serverPackages [

	^ serverPackages ifNil: [ 
		  serverPackages := self commonPackagesFor: self serverDCR in: serverNodes ]
]

{ #category : #building }
MiNewVisuBuilder >> services [

	^ services ifNil: [ services := self elements ]
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
	self container add: rootShape
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
	RSLocation new
		left;
		top;
		inner;
		move: label on: shape baseRectangle.
	^ shape
]

{ #category : #visiting }
MiNewVisuBuilder >> visitElement: aMiNVElement [

	| hNode |
	hNode := HNode new
		         rawModel: aMiNVElement model;
		         name: aMiNVElement model asString;
		         yourself.
	rootNode add: hNode.
	^ self shapeFor: hNode
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
				   yourself)
]
