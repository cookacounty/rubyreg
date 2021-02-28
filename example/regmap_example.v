module regmap_example(
	// Main clock, enable, and reset
	input              rst_l,
	input              clk,
	input              enable,
	input              sw_rst,

	// Register control
	input              reg_wr,
	input        [7:0] reg_rd_addr_a,
	input        [7:0] reg_rd_addr_b,
	input        [7:0] reg_wr_addr,
	input        [7:0] reg_wdat,
	input        [7:0] reg_mask,
	output reg   [7:0] reg_rdat_a,
	output reg   [7:0] reg_rdat_b
	
	,input nvm_blown_status
	,input nvm_busy
	
	,output reg r_anamon_en
	,output reg [3:0] r_anamon_sel
	,output reg r_digimon_en
	,output reg [3:0] r_digimon_sel
	,output reg [7:0] r_spare_vol_0
	,output reg r_nvm_reload
	,output reg r_nvm_blow
	,output reg [2:0] r_iref_trim
	,output reg [4:0] r_vref_trim
	,output reg [7:0] r_spare_nvm
	
	,output [7:0] reg_0x48
	,output [7:0] reg_0x49
	,output [7:0] reg_0x4A
	,output [7:0] reg_0xDF
	,output [7:0] reg_0xE0
	,output [7:0] reg_0xE1


);

// Read Decode A
always @(*) begin
	reg_rdat_a = 0;
	case(reg_rd_addr_a) 
		72: begin 
			reg_rdat_a[0]= r_anamon_en;
			reg_rdat_a[4:1]= r_anamon_sel;
		end
		73: begin 
			reg_rdat_a[0]= r_digimon_en;
			reg_rdat_a[4:1]= r_digimon_sel;
		end
		74: begin 
			reg_rdat_a[7:0]= r_spare_vol_0;
		end
		223: begin 
			reg_rdat_a[3]= nvm_blown_status;
			reg_rdat_a[2]= nvm_busy;
			reg_rdat_a[1]= r_nvm_reload;
			reg_rdat_a[0]= r_nvm_blow;
		end
		224: begin 
			reg_rdat_a[2:0]= r_iref_trim;
			reg_rdat_a[7:3]= r_vref_trim;
		end
		225: begin 
			reg_rdat_a[7:0]= r_spare_nvm;
		end
		default: begin
			reg_rdat_a = 0;
		end
	endcase
end

// Read Decode B
always @(*) begin
	reg_rdat_b = 0;
	case(reg_rd_addr_b) 
		72: begin 
			reg_rdat_b[0]= r_anamon_en;
			reg_rdat_b[4:1]= r_anamon_sel;
		end
		73: begin 
			reg_rdat_b[0]= r_digimon_en;
			reg_rdat_b[4:1]= r_digimon_sel;
		end
		74: begin 
			reg_rdat_b[7:0]= r_spare_vol_0;
		end
		223: begin 
			reg_rdat_b[3]= nvm_blown_status;
			reg_rdat_b[2]= nvm_busy;
			reg_rdat_b[1]= r_nvm_reload;
			reg_rdat_b[0]= r_nvm_blow;
		end
		224: begin 
			reg_rdat_b[2:0]= r_iref_trim;
			reg_rdat_b[7:3]= r_vref_trim;
		end
		225: begin 
			reg_rdat_b[7:0]= r_spare_nvm;
		end
		default: begin
			reg_rdat_b = 0;
		end
	endcase
end

// Address write decode logic

assign PMIC_UDR_amon_en = reg_wr && (reg_wr_addr == 72);
assign PMIC_UDR_digmon_en = reg_wr && (reg_wr_addr == 73);
assign PMIC_UDR_spare_en = reg_wr && (reg_wr_addr == 74);
assign NVM_CONTROL_en = reg_wr && (reg_wr_addr == 223);
assign nvm_reg_0x02_en = reg_wr && (reg_wr_addr == 224);
assign nvm_reg_0x03_en = reg_wr && (reg_wr_addr == 225);

// Raw register logic

assign reg_0x48 = {1'b0,1'b0,1'b0,r_anamon_sel[3],r_anamon_sel[2],r_anamon_sel[1],r_anamon_sel[0],r_anamon_en};
assign reg_0x49 = {1'b0,1'b0,1'b0,r_digimon_sel[3],r_digimon_sel[2],r_digimon_sel[1],r_digimon_sel[0],r_digimon_en};
assign reg_0x4A = {r_spare_vol_0[7],r_spare_vol_0[6],r_spare_vol_0[5],r_spare_vol_0[4],r_spare_vol_0[3],r_spare_vol_0[2],r_spare_vol_0[1],r_spare_vol_0[0]};
assign reg_0xDF = {1'b0,1'b0,1'b0,1'b0,nvm_blown_status,nvm_busy,r_nvm_reload,r_nvm_blow};
assign reg_0xE0 = {r_vref_trim[4],r_vref_trim[3],r_vref_trim[2],r_vref_trim[1],r_vref_trim[0],r_iref_trim[2],r_iref_trim[1],r_iref_trim[0]};
assign reg_0xE1 = {r_spare_nvm[7],r_spare_nvm[6],r_spare_nvm[5],r_spare_nvm[4],r_spare_nvm[3],r_spare_nvm[2],r_spare_nvm[1],r_spare_nvm[0]};

// Field next state logic

wire  anamon_en_nxt = sw_rst ? 0 : PMIC_UDR_amon_en ? ((~reg_mask[0] & reg_wdat[0]) | (reg_mask[0] & r_anamon_en)) : r_anamon_en;
wire [3:0] anamon_sel_nxt = sw_rst ? 0 : PMIC_UDR_amon_en ? ((~reg_mask[4:1] & reg_wdat[4:1]) | (reg_mask[4:1] & r_anamon_sel)) : r_anamon_sel;
wire  digimon_en_nxt = sw_rst ? 0 : PMIC_UDR_digmon_en ? ((~reg_mask[0] & reg_wdat[0]) | (reg_mask[0] & r_digimon_en)) : r_digimon_en;
wire [3:0] digimon_sel_nxt = sw_rst ? 0 : PMIC_UDR_digmon_en ? ((~reg_mask[4:1] & reg_wdat[4:1]) | (reg_mask[4:1] & r_digimon_sel)) : r_digimon_sel;
wire [7:0] spare_vol_0_nxt = sw_rst ? 0 : PMIC_UDR_spare_en ? ((~reg_mask[7:0] & reg_wdat[7:0]) | (reg_mask[7:0] & r_spare_vol_0)) : r_spare_vol_0;
wire  nvm_reload_nxt = sw_rst ? 0 : NVM_CONTROL_en ? ((~reg_mask[1] & reg_wdat[1]) | (reg_mask[1] & r_nvm_reload)) : 0;
wire  nvm_blow_nxt = sw_rst ? 0 : NVM_CONTROL_en ? ((~reg_mask[0] & reg_wdat[0]) | (reg_mask[0] & r_nvm_blow)) : 0;
wire [2:0] iref_trim_nxt = sw_rst ? 0 : nvm_reg_0x02_en ? ((~reg_mask[2:0] & reg_wdat[2:0]) | (reg_mask[2:0] & r_iref_trim)) : r_iref_trim;
wire [4:0] vref_trim_nxt = sw_rst ? 0 : nvm_reg_0x02_en ? ((~reg_mask[7:3] & reg_wdat[7:3]) | (reg_mask[7:3] & r_vref_trim)) : r_vref_trim;
wire [7:0] spare_nvm_nxt = sw_rst ? 0 : nvm_reg_0x03_en ? ((~reg_mask[7:0] & reg_wdat[7:0]) | (reg_mask[7:0] & r_spare_nvm)) : r_spare_nvm;

// Registers
always@(posedge clk or negedge rst_l) begin
	if (!rst_l) begin 
		r_anamon_en <= 0;	
		r_anamon_sel <= 0;	
		r_digimon_en <= 0;	
		r_digimon_sel <= 0;	
		r_spare_vol_0 <= 0;	
		r_nvm_reload <= 0;	
		r_nvm_blow <= 0;	
		r_iref_trim <= 0;	
		r_vref_trim <= 0;	
		r_spare_nvm <= 0;	
	end else if (enable) begin
		r_anamon_en <= anamon_en_nxt;	
		r_anamon_sel <= anamon_sel_nxt;	
		r_digimon_en <= digimon_en_nxt;	
		r_digimon_sel <= digimon_sel_nxt;	
		r_spare_vol_0 <= spare_vol_0_nxt;	
		r_nvm_reload <= nvm_reload_nxt;	
		r_nvm_blow <= nvm_blow_nxt;	
		r_iref_trim <= iref_trim_nxt;	
		r_vref_trim <= vref_trim_nxt;	
		r_spare_nvm <= spare_nvm_nxt;	
	end
end

endmodule
