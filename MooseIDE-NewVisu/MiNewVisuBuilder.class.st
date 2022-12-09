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
		'appServiceUID'
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
MiNewVisuBuilder >> build [

	rootNode := HNode new.
	rootNode addAll: self services.
	rootNode addAll: self clients.
	rootNode addAll: self implementations.
	rootNode addAll: self serverDCR.
	self setServerDCRDependencies.
	self setAppServiceUIDDependencies.

	self renderIn: self container.
	^ self container
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
		        collapse;
		        yourself.
	allEntities at: anEntity put: node.
	^ node
]

{ #category : #building }
MiNewVisuBuilder >> buildShapes [

	| servicesShapes layout width implementationsShapes allShapes clientsShapes clients2Shapes clientShape serverDCRShapes serverShape |
	layout := RSVerticalLineLayout new
		          alignCenter;
		          yourself.
	clientShape := RSComposite new.
	serverShape := RSComposite new.
	servicesShapes := self services
		                  collect: [ :s | 
		                  (self shapeFor: s) sparent: self container ]
		                  as: RSGroup.
	clientsShapes := self clients
		                 collect: [ :s | 
		                 (self shapeFor: s) sparent: self container ]
		                 as: RSGroup.
	implementationsShapes := self implementations
		                         collect: [ :s | 
		                         (self shapeFor: s) sparent: self container ]
		                         as: RSGroup.
	clients2Shapes := (self clients collect: [ :c | 
		                   | cls nn |
		                   cls := self clientNodesFor: c.
		                   nn := HNode new
			                         name: cls size asString;
			                         children: cls;
			                         collapse;
			                         yourself.
		                   nn dependencyTo: c.
		                   rootNode add: nn.
		                   nn ])
		                  collect: [ :n | 
		                  (self shapeFor: n) sparent: self container ]
		                  as: RSGroup.

	serverDCRShapes := self serverDCR
		                   collect: [ :s | 
		                   (self shapeFor: s) sparent: self container ]
		                   as: RSGroup.
	
	(serverDCRShapes detect: [ :s | s model name = 'AppServiceUID' ]) 
		ifNotNil: [ :s | s border: ((RSBorder new
			 width: 2;
			 capSquare;
			 joinMiter;
			 color: Color red;
			 yourself))].
	RSFlowLayout new on: serverDCRShapes.

	width := (servicesShapes collect: #width) max.
	servicesShapes do: [ :s | s width: width ].

	width := (implementationsShapes collect: #width) max.
	implementationsShapes do: [ :s | s width: width ].

	width := (clientsShapes collect: #width) max.
	clientsShapes do: [ :s | s width: width ].

	width := (clients2Shapes collect: #width) max.
	clients2Shapes do: [ :s | s width: width ].

	layout on: servicesShapes.
	layout on: clientsShapes.
	layout on: clients2Shapes.
	layout on: implementationsShapes.


	clientShape
		addAll: clients2Shapes;
		addAll: clientsShapes;
		addAll: servicesShapes;
		sparent: self container.

	serverShape
		addAll: implementationsShapes;
		addAll: serverDCRShapes;
		sparent: self container.

	allShapes := RSGroup new.
	allShapes
		add: clientShape;
		add: serverShape.
	"addAll: clientsShapes;"
	"addAll: servicesShapes;"

	clientShape border: (RSBorder new
			 width: 2;
			 capSquare;
			 joinMiter;
			 color: Smalltalk ui theme textColor;
			 dashArray: #( 5 10 );
			 yourself).
	serverShape border: (RSBorder new
			 width: 2;
			 capSquare;
			 joinMiter;
			 color: Smalltalk ui theme textColor;
			 dashArray: #( 5 10 );
			 yourself).
	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: { 
				clients2Shapes.
				clientsShapes.
				servicesShapes }.
	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: { 
				implementationsShapes.
				serverDCRShapes }.
	self container schildren:
		allShapes , clients2Shapes , clientsShapes , servicesShapes
		, implementationsShapes , serverDCRShapes.
	self container addAll: allShapes.
	clientShape
		adjustToChildren;
		padding: 50.
	serverShape
		adjustToChildren;
		padding: 50.
	RSHorizontalLineLayout new
		alignMiddle;
		horizontalGap: 400;
		on: { 
				clientShape.
				serverShape }
]

{ #category : #accessing }
MiNewVisuBuilder >> clientNodesFor: anHNode [

	| node cl |
	node := anHNode rawModel.
	cl := node incomingReferences collectAsSet: [ :r | r source ].

	^ cl collect: [ :c | self buildNodeFromEntity: c ]
]

{ #category : #building }
MiNewVisuBuilder >> clients [

	^ clients ifNil: [ 
		  | nodes |
		  nodes := Set new.
		  self services do: [ :s | 
			        s rawModel incomingReferences do: [ :r | 
				        | client |
				        client := self buildNodeFromEntity:
					                  (r source atScopeWithProperty: [ :e | 
						                   e isClass and: [ e isAnonymousClass not ] ])
						                  anyOne.
				        client dependencyTo: s.
				        nodes add: client ] ].
		  clients := nodes asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> colorFor: node [
	^ Color fromHexString: '7FC6F6'
]

{ #category : #building }
MiNewVisuBuilder >> elements [

	| entities |
	entities := OrderedCollection new.
	entities addAll:
		(mapModel entities sort: [ :a :b | a name < b name ]).

	^ entities collect: [ :e | self buildNodeFromEntity: e ]
]

{ #category : #building }
MiNewVisuBuilder >> highlightable [
	^ highlightable ifNil: [ 
		highlightable := RSHighlightable new
			highlightShapes: [ :shape | 
				| list |
				list := shape connectedLines copy.
				list add: (shape propertyAt: #background).
				list 
				 ];
			when: RSHighlightEvent do: [ :evt |
				| color |
				color := evt shape isNode
					 ifTrue: [ evt shape color muchDarker ]
					 ifFalse: [ Color red ].
				highlightable record: evt shape selector: #color value: color ];
			when: RSUnHighlightEvent do: [ :evt | 
				highlightable restore: evt shape selector: #color ];
			yourself.
		 ].
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
						                                   sub isAbstract isNil ] ]).
			                     s dependencyTo: newEntity.
			                     newEntity ] ]
]

{ #category : #initialization }
MiNewVisuBuilder >> initialize [

	super initialize.
	allEntities := Dictionary new
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
		line announcer: announcer.
		(line from model rawModel isMooseEntity and: [ 
			 (line from model rawModel superclassHierarchy anySatisfy: [ :c | 
				  c name = 'RemoteService' ]) and: [ 
				 line to model rawModel superclassHierarchy anySatisfy: [ :c | 
					 c name = 'CAInovelanRemoteServiceServlet' ] ] ]) ifTrue: [ 
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
			  cli := ((i rawModel query: #out with: FamixTReference)
				          collect: [ :c | self rootClass: c target ]
				          thenReject: #isStub) asSet.
			  cli do: [ :e | 
				  allEntities
					  at: e
					  ifPresent: [ :n | i dependencyTo: n  ]
					  ifAbsent: [ sdcr add: (self buildNodeFromEntity: e) ] ] ].
		  serverDCR := sdcr asOrderedCollection ]
]

{ #category : #building }
MiNewVisuBuilder >> services [

	^ services ifNil: [ services := self elements ]
]

{ #category : #building }
MiNewVisuBuilder >> setAppServiceUIDDependencies [

	(self appServiceUID rawModel query: #in with: FamixTReference) do: [ :r | 
		allEntities
			at: r source
			ifPresent: [ :n | n dependencyTo: self appServiceUID ].
		allEntities
			at: (self rootClass: r source)
			ifPresent: [ :n | n dependencyTo: self appServiceUID ] ]
]

{ #category : #building }
MiNewVisuBuilder >> setServerDCRDependencies [

	self serverDCR do: [ :s | 
		(s rawModel query: #out with: FamixTReference) do: [ :r | 
			allEntities at: r target ifPresent: [ :n | s dependencyTo: n ] ] ]
]

{ #category : #building }
MiNewVisuBuilder >> shapeFor: node [

	| shape |
	shape := RSComposite new
		         model: node;
		         color: Smalltalk ui theme buttonColor;
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
