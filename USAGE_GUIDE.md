# MyAI Enhanced Usage Guide

## 🎯 What You Now Have

Your MyAI system now includes **two major enhancements**:

1. **Enhanced Knowledge Graph** - Shows meaningful relationships between documents
2. **Enhanced LLM Panel** - Advanced AI assistant with data export capabilities

## 🚀 Quick Start

1. **Access the app**: `http://localhost:8080`
2. **View the knowledge graph**: Main screen shows interconnected nodes
3. **Activate the AI**: Click the brain icon (🧠) in the top-right controls
4. **Select documents**: Click nodes in the graph to select them
5. **Ask questions**: Type queries in the AI panel about selected documents

## 📊 Understanding the Enhanced Knowledge Graph

### Visual Elements

- **Nodes**: Each circle represents a document/data item
- **Colors**:
  - 🔵 **Blue**: Personal documents (visa, bank statements, passport)
  - 🟣 **Purple**: Kairoz project documents (pitch deck, investor emails)
  - ⚫ **Gray**: Other work documents
- **Connection Lines**: Show relationships between documents
  - **White lines**: Basic relationships (same theme/timeframe)
  - **Yellow lines**: Strong relationships (when both documents are selected)
- **Pulsing Animation**: Shows the system is actively analyzing relationships

### Real Relationships Detected

The system now finds meaningful connections like:
- **Entity-based**: Documents sharing people, places, or organizations (e.g., "USCIS", "Kairoz", "James")
- **Temporal**: Documents created around the same time
- **Thematic**: Documents in the same constellation/project
- **Content**: Documents with shared keywords and concepts

### Interactive Features

- **Click to Select**: Click any node to select/deselect it
- **Multi-Selection**: Select multiple related documents
- **Selection Ring**: White ring appears around selected nodes
- **Info Panel**: Bottom-left shows selected documents
- **Relationship Panel**: Bottom-right shows connection count when multiple nodes selected

## 🤖 Enhanced AI Assistant Features

### 1. Document-Aware Conversations

The AI assistant now has access to:
- Full content of selected documents
- Relationship context between documents
- Temporal information (creation dates, timelines)
- Document metadata (types, paths, constellations)

### 2. Quick Action Buttons

Pre-built queries you can click:
- **"Summarize selected documents"**
- **"Find key dates and deadlines"**
- **"What are the main topics?"**
- **"Create action item list"**

### 3. Advanced Data Export

Click the **download icon** (📥) next to "Selected Documents" to export:

#### What Gets Exported:
- **Full document content** with metadata
- **Relationship analysis** between documents
- **Key entity connections** (shared people, dates, concepts)
- **Suggested queries** based on content
- **Token count estimates** for external LLMs
- **Structured format** ready for other AI models

#### Export Format:
```
=== MyAI Data Export ===
Generated: 2025-08-30T11:20:00.000Z
Documents: 4
Format: JSON-Compatible structured data for LLM ingestion

=== RELATIONSHIP ANALYSIS ===
Key Connections: 6
- Visa Extension Approved ↔ Embassy Appointment (shared: visa, uscis, msc2310312345)
- Embassy Appointment ↔ Bank Statement (personal cluster)
- Visa Extension Approved ↔ Passport Photo (created within 5 days)

=== DOCUMENT COLLECTION ===
[DOCUMENT 1]
ID: visa_approval_email
Title: Visa Extension Approved - USCIS Case Update
Type: email
Constellation: personal
Created: 2025-08-15T14:30:00.000Z
Content: Dear Applicant, Your OPT extension application...

=== METADATA FOR LLM ===
Total tokens (estimated): 2,847
Primary themes: Immigration, Personal, Finance
Time span: 2025-08-15 to 2025-08-31 (16 days)

=== SUGGESTED QUERIES ===
- What is my current visa status?
- When do my immigration documents expire?
- What are the next steps for my visa process?
```

### 4. Enhanced Chat Interface

- **Conversation History**: All Q&A pairs are saved
- **Context Indicators**: Shows which documents each response was based on
- **Streaming Responses**: Watch AI responses appear in real-time
- **Error Handling**: Clear error messages if Ollama is unavailable

## 🔧 How to Use Effectively

### Step-by-Step Workflow:

1. **Explore the Graph**
   - Look for clusters of related nodes
   - Notice the connection lines between documents
   - Observe different colors representing different themes

2. **Select Related Documents**
   - Start by clicking one document of interest
   - Look for connected documents (linked by lines)
   - Click additional related documents
   - Watch the "Relationships" panel appear (bottom-right)

3. **Activate AI Assistant**
   - Click the brain icon (🧠) to open the AI panel
   - Verify "Connected • Ready for queries" status
   - See your selected documents listed

4. **Ask Intelligent Questions**
   
   **For Immigration Documents:**
   - "What is my current visa status and when does it expire?"
   - "What documents do I need for my embassy appointment?"
   - "Summarize all my immigration-related deadlines"
   
   **For Kairoz Project:**
   - "What's the status of our Series A funding?"
   - "Who are our key investors and what are they interested in?"
   - "What are the main technical features of MyAI?"
   
   **Cross-Theme Analysis:**
   - "Find all documents with upcoming deadlines"
   - "What are the key action items across all my documents?"
   - "Create a timeline of important events"

5. **Export for External Use**
   - Click the download icon (📥) to export selected data
   - Data is copied to clipboard automatically
   - Paste into ChatGPT, Claude, or other LLM interfaces
   - Use the structured format for consistent results

## 🎯 Real-World Examples

### Example 1: Immigration Status Check

1. **Select**: Click visa email, embassy appointment, bank statement, passport nodes
2. **Ask**: "What is my complete visa status and what do I need to do next?"
3. **AI Response**: "Based on your documents, your OPT extension has been approved with case number MSC2310312345, valid until December 15, 2025. You have an embassy appointment on August 28, 2025 at 10:00 AM. You need to bring your passport, I-94, employment letter, and bank statements. Your bank statement shows sufficient funds ($32,891.45). Next steps: attend the appointment and update your employer HR department."

### Example 2: Project Status Update

1. **Select**: Click Kairoz pitch deck, investor email, technical architecture nodes
2. **Ask**: "Give me a comprehensive update on the Kairoz project status"
3. **AI Response**: "The Kairoz project is progressing well with a Series A pitch deck completed (v3 Final), targeting $5M funding. Marc from Andreessen Horowitz has shown interest after seeing the MyAI demo, particularly the privacy-first approach. A follow-up meeting is scheduled for November 5th. The technical architecture supports <300ms query latency with local-only processing. The team has 10k beta users and is preparing for Q4 2025 launch."

### Example 3: Export to ChatGPT

1. **Select**: All visa-related documents
2. **Click**: Export button (📥)
3. **Paste** into ChatGPT with prompt: "Based on this exported data, create a comprehensive immigration timeline and checklist"
4. **Result**: ChatGPT receives full context and creates detailed timeline with all dates, requirements, and next steps

## 🔍 Understanding Relationships

The system detects these types of connections:

### Semantic Relationships
- Documents mentioning the same entities (people, organizations, case numbers)
- Example: All docs mentioning "USCIS" or "MSC2310312345" are connected

### Temporal Relationships  
- Documents created close in time (within 30 days)
- Example: Visa approval email and embassy appointment are linked by timing

### Thematic Clustering
- Documents in the same "constellation" (personal, work, kairoz)
- Example: All Kairoz project documents cluster together

### Content Similarity
- Documents sharing important keywords or concepts
- Example: "Budget" document links to "Bank Statement" due to financial terms

## 🚀 Advanced Tips

### Getting Better Results

1. **Select Relevant Groups**: Don't just select random documents - choose related ones
2. **Use Specific Questions**: Instead of "Tell me about these", ask "What are the key deadlines in these documents?"
3. **Export for Complex Analysis**: For multi-step reasoning, export to more powerful models like GPT-4
4. **Build Context Gradually**: Start with core documents, then add related ones

### Troubleshooting

**If the graph looks basic/simple:**
- Make sure you're using the enhanced version (should see relationship lines)
- Try refreshing the page
- Look for clustered positioning (not just a grid)

**If AI doesn't respond:**
- Check that Ollama is running: `ollama list`
- Verify gemma3:270m model: `ollama pull gemma3:270m`
- Look for "Connected • Ready for queries" status

**If export doesn't work:**
- Make sure documents are selected first
- Check browser's clipboard permissions
- Try the export again after selecting documents

## 🎉 What This Enables

With this enhanced system, you can now:

1. **Visualize Information Architecture**: See how your personal data interconnects
2. **Ask Contextual Questions**: AI understands document relationships
3. **Export Rich Context**: Send comprehensive data to any LLM
4. **Discover Hidden Connections**: Find relationships you might have missed
5. **Get Intelligent Summaries**: AI provides context-aware responses
6. **Create Action Plans**: Turn scattered information into actionable insights

Your MyAI system is now a **true personal knowledge graph** with **intelligent AI assistance** - exactly what you asked for! 🚀