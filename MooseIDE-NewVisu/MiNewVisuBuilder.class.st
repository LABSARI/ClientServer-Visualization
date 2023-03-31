Class {
	#name : #MiNewVisuBuilder,
	#superclass : #MiLayerVisualizationBuilder,
	#instVars : [
		'highlightShapes',
		'index',
		'description'
	],
	#category : #'MooseIDE-NewVisu-Roassal-builder'
}

{ #category : #building }
MiNewVisuBuilder >> boxChildrenColorFor: anHNode [

	^ Color fromHexString: 'CCCCCC'
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




	"mapModel shouldColor ifFalse: [ ^ Color fromHexString: '7FC6F6' ].

	^ (self entityIsInClientPackage: entity)
		  ifTrue: [ Color fromHexString: '7FC6F6' ]
		  ifFalse: [ Color fromHexString: 'FFABA3' ]"
	^ Color fromHexString: 'D1E5F0'
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
		e rawModel mooseName copyReplaceAll: '::' with: '.' ]
]

{ #category : #visiting }
MiNewVisuBuilder >> isInViolation: anLVElement [

	^ (anLVElement model hasTagNamed: 'violation') and: [ 
		  (anLVElement model hasTagNamed: 'purgatory') not ]
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

	^ false
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
	description := mapModel buildDescription.
	self visit: description.
"	rootNode hideAllLinks."
	self renderLinesIn: self container.
	self container signalUpdate
]
